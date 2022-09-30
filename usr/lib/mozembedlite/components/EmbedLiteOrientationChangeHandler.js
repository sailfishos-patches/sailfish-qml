/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cr = Components.results;

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");
const { OrientationChangeHandler } = ChromeUtils.import("chrome://embedlite/content/OrientationChangeHandler.jsm")

XPCOMUtils.defineLazyServiceGetter(Services, "embedlite",
                                   "@mozilla.org/embedlite-app-service;1",
                                   "nsIEmbedAppService");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

function EmbedLiteOrientationChangeHandler()
{
  Logger.debug("JSComp: EmbedLiteOrientationChangeHandler.js loaded");
}

EmbedLiteOrientationChangeHandler.prototype = {
  classID: Components.ID("{39c15bb1-0a5c-42ff-979a-f2cfd966743c}"),
  _orientationListeners: {},

  _initialize: function() {
    Services.obs.addObserver(this, "embedliteviewcreated", true);
    Services.obs.addObserver(this, "domwindowclosed", true);
  },

  observe: function(aSubject, aTopic, aData) {
    let self = this;
    switch (aTopic) {
    case "app-startup": {
      self._initialize();
      break;
    }

    case "embedliteviewcreated": {
      self.onWindowOpen(aSubject);
      break;
    }
    case "domwindowclosed": {
      self.onWindowClosed(aSubject);
      break;
    }
    }
  },

  onWindowOpen: function(aWindow) {
    this._orientationListeners[aWindow] = new OrientationChangeHandler(aWindow);
    Services.embedlite.chromeEventHandler(aWindow).addEventListener("DOMContentLoaded", this._orientationListeners[aWindow], false);
  },

  onWindowClosed: function(aWindow) {
    let chromeEventHandler = Services.embedlite.chromeEventHandler(aWindow);
    if (chromeEventHandler) {
      chromeEventHandler.removeEventListener("DOMContentLoaded", this._orientationListeners[aWindow], false);
    }
    delete this._orientationListeners[aWindow];
  },

  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver, Ci.nsISupportsWeakReference])
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([EmbedLiteOrientationChangeHandler]);
