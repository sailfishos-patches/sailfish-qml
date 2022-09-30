/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cr = Components.results;

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");
const { PrivateBrowsingUtils } = ChromeUtils.import("resource://gre/modules/PrivateBrowsingUtils.jsm");

XPCOMUtils.defineLazyModuleGetter(this, "NetUtil",
                                  "resource://gre/modules/NetUtil.jsm");
XPCOMUtils.defineLazyServiceGetter(Services, "embedlite",
                                   "@mozilla.org/embedlite-app-service;1",
                                   "nsIEmbedAppService");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

// Common helper service

function EmbedLiteErrorPageHandler()
{
  Logger.debug("JSComp: EmbedLiteErrorPageHandler.js loaded");
}

function EventLinkListener(aWindow)
{
  this._winID = Services.embedlite.getIDByWindow(aWindow);
  this._targetWindow = Services.embedlite.getContentWindowByID(this._winID);
  this._docShell = aWindow.docShell
}

EventLinkListener.prototype = {
  _winID: -1,
  _targetWindow: null,
  _docShell: null,
  handleEvent: function Input_handleEvent(aEvent) {
    switch (aEvent.type) {
      case "DOMContentLoaded": {
        let target = aEvent.originalTarget;
        // Attach a listener to watch for "click" events bubbling up from error
        // pages and other similar page. This lets us fix bugs like 401575 which
        // require error page UI to do privileged things, without letting error
        // pages have any privilege themselves.
        if (/^about:/.test(target.documentURI)) {
          ErrorPageEventHandler._targetWindow = this._targetWindow;
          ErrorPageEventHandler._docShell = this._docShell;
          Services.embedlite.chromeEventHandler(this._targetWindow).addEventListener("click", ErrorPageEventHandler, true);
          let listener = function() {
            try {
              Services.embedlite.chromeEventHandler(this._targetWindow).removeEventListener("click", ErrorPageEventHandler, true);
            } catch (e) {}

            try {
              Services.embedlite.chromeEventHandler(this._targetWindow).removeEventListener("pagehide", listener, true);
            } catch (e) {}
            ErrorPageEventHandler._targetWindow = null;
            ErrorPageEventHandler._docShell = null;
          }.bind(this);

          Services.embedlite.chromeEventHandler(this._targetWindow).addEventListener("pagehide", listener, true);
        }

        break;
      }
    }
  },

  QueryInterface: ChromeUtils.generateQI([Ci.nsIDOMEventListener])
};

EmbedLiteErrorPageHandler.prototype = {
  classID: Components.ID("{ad8b729c-b000-11e2-8ed2-bfd39531b0a6}"),
  _linkListeners: {},

  observe: function (aSubject, aTopic, aData) {
    let self = this;
    switch(aTopic) {
      case "app-startup": {
        // Name of alternate about: page for certificate errors (when undefined, defaults to about:neterror)
        Services.obs.addObserver(this, "embedliteviewcreated", true);
        Services.obs.addObserver(this, "domwindowclosed", true);
        Services.obs.addObserver(this, "xpcom-shutdown", true);
        break;
      }
      case "embedliteviewcreated": {
        self.onWindowOpen(aSubject);
        break;
      }
      case "domwindowclosed": {
        self.onWindowClose(aSubject);
        break;
      }
      case "xpcom-shutdown": {
        Services.obs.removeObserver(this, "embedliteviewcreated", true);
        Services.obs.removeObserver(this, "domwindowclosed", true);
        Services.obs.removeObserver(this, "xpcom-shutdown", true);
      }
    }
  },

  onWindowOpen: function ss_onWindowOpen(aWindow) {
    // Return if window has already been initialized
    this._linkListeners[aWindow] = new EventLinkListener(aWindow);
    try {
      Services.embedlite.chromeEventHandler(aWindow).addEventListener("DOMContentLoaded", this._linkListeners[aWindow], false);
    } catch (e) {}
  },

  onWindowClose: function ss_onWindowClose(aWindow) {
    // Ignore windows not tracked by SessionStore
    try {
      Services.embedlite.chromeEventHandler(aWindow).removeEventListener("DOMContentLoaded", this._linkListeners[aWindow], false);
    } catch (e) {}
    delete this._linkListeners[aWindow];
  },

  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver, Ci.nsISupportsWeakReference])
};

var ErrorPageEventHandler = {
  _targetWindow: null,
  _docShell: null,
  handleEvent: function(aEvent) {
    switch (aEvent.type) {
      case "click": {
        // Don't trust synthetic events
        if (!aEvent.isTrusted)
          return;

        let target = aEvent.originalTarget;
        let errorDoc = target.ownerDocument;

        // If the event came from an ssl error page, it is probably either the "Add
        // Exception…" or "Get me out of here!" button
        if (/^about:certerror\?e=nssBadCert/.test(errorDoc.documentURI)) {
          let perm = errorDoc.getElementById("permanentExceptionButton");
          let temp = errorDoc.getElementById("temporaryExceptionButton");
          if (target == temp || target == perm) {
            // Handle setting an cert exception and reloading the page
            let uri = Services.io.newURI(errorDoc.location.href);
            let securityInfo = this._docShell.failedChannel.securityInfo;
            securityInfo.QueryInterface(Ci.nsITransportSecurityInfo);
            let cert = securityInfo.serverCert;
            let overrideService = Cc["@mozilla.org/security/certoverride;1"]
                                    .getService(Ci.nsICertOverrideService);
            let flags = 0;
            if (securityInfo.isUntrusted) {
              flags |= overrideService.ERROR_UNTRUSTED;
            }
            if (securityInfo.isDomainMismatch) {
              flags |= overrideService.ERROR_MISMATCH;
            }
            if (securityInfo.isNotValidAtThisTime) {
              flags |= overrideService.ERROR_TIME;
            }
            let temporary = (target == temp) ||
                             PrivateBrowsingUtils.isWindowPrivate(errorDoc.defaultView);
            overrideService.rememberValidityOverride(uri.asciiHost, uri.port, cert, flags,
                                                     temporary);
            errorDoc.location.reload();
          } else if (target == errorDoc.getElementById("getMeOutOfHereButton")) {
            errorDoc.location = "about:home";
          }
        }
        break;
      }
    }
  }
};


this.NSGetFactory = XPCOMUtils.generateNSGetFactory([EmbedLiteErrorPageHandler]);
