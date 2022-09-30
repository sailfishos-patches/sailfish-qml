/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2020 Open Mobile Platform LLC.
 */

"use strict";

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cr = Components.results;

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");
const { NetErrorHelper } = ChromeUtils.import("chrome://embedlite/content/NetErrorHelper.jsm")

XPCOMUtils.defineLazyModuleGetters(this, {
  AboutCertViewerHandler: "resource://gre/modules/AboutCertViewerHandler.jsm",
  ContentLinkHandler: "chrome://embedlite/content/ContentLinkHandler.jsm",
  Feeds: "chrome://embedlite/content/Feeds.jsm"
});

let embedChromeManager = this

XPCOMUtils.defineLazyServiceGetter(Services, "embedlite",
                                    "@mozilla.org/embedlite-app-service;1",
                                    "nsIEmbedAppService");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

function EmbedLiteChromeListener(aWindow)
{

  this.windowId = Services.embedlite.getIDByWindow(aWindow);
  // Services.embedlite.getContentWindowByID will return the same as aWindow
  this.targetDOMWindow = aWindow;
  this.docShell = aWindow.docShell;
  ContentLinkHandler.init(this);
}

EmbedLiteChromeListener.prototype = {
  targetDOMWindow: null,
  docShell: null,
  windowId: -1,
  userRequested: "",

  // -------------------------------------------------------------------------
  // Added call through function to mimic chrome and satisfy ContentLinkHandler
  addEventListener(eventType, callback, options) {
    let chromeEventHandler = Services.embedlite.chromeEventHandler(this.targetDOMWindow);
    chromeEventHandler.addEventListener(eventType, callback, options);
  },

  removeEventListener(eventType, callback, options) {
    let chromeEventHandler = Services.embedlite.chromeEventHandler(this.targetDOMWindow);
    chromeEventHandler.removeEventListener(eventType, callback, options);
  },

  sendAsyncMessage(messageName, message) {
    try {
      Services.embedlite.sendAsyncMessage(this.windowId, messageName, JSON.stringify(message));
    } catch (e) {
      Logger.warn("EmbedLiteChromeListener: sending async message failed", e)
    }
  },

  get content() {
    return this.targetDOMWindow
  },
  // -------------------------------------------------------------------------

  handleEvent(event) {
    let window = this.targetDOMWindow;

    var messageName;
    var message = {}

    switch (event.type) {
    case "DOMMetaAdded":
      messageName = "chrome:metaadded"
      break;
    case "DOMContentLoaded":
      let doc = this.docShell.contentViewer.DOMDocument;
      var docURI = doc && doc.documentURI || "";
      if (!docURI.startsWith("about:blank")) {
        messageName = "chrome:contentloaded";
        message["docuri"] = docURI;
      }

      if (docURI.startsWith("about:neterror")) {
        NetErrorHelper.attachToBrowser(this);
      }
      break;
    case "DOMWillOpenModalDialog":
    case "DOMModalDialogClosed":
    case "DOMWindowClose":
      messageName = "chrome:winopenclose";
      message["type"] = event.type;
      break;
    case "DOMPopupBlocked":
      let permissions = Services.perms.getAllForPrincipal(Services.scriptSecurityManager.createContentPrincipal(event.popupWindowURI, {}));
      for (let permission of permissions) {
        if (permission.type == "popup" && permission.capability == Ci.nsIPermissionManager.DENY_ACTION) {
          // Ignore popup
          return;
        }
      }
      messageName = "embed:popupblocked";
      message["host"] = event.popupWindowURI.displaySpec;
      break;
    }

    if (messageName) {
      this.sendAsyncMessage(messageName, message);
    }
  },

  QueryInterface: ChromeUtils.generateQI([Ci.nsIDOMEventListener,
                                          Ci.nsISupportsWeakReference])
};

function EmbedLiteChromeManager()
{
  Logger.debug("JSComp: EmbedLiteChromeManager.js loaded");
}

EmbedLiteChromeManager.prototype = {
  classID: Components.ID("{9d17cd12-da27-4f4c-957c-f355910ac2e9}"),
  _chromeListeners: {},
  _lastCreatedWindowId: 0,

  _initialize() {
    // Use "embedliteviewcreated" instead of "domwindowopened".
    Services.obs.addObserver(this, "embedliteviewcreated", true);
    Services.obs.addObserver(this, "embed-network-link-status", true)
    Services.obs.addObserver(this, "domwindowclosed", true);
    Services.obs.addObserver(this, "keyword-uri-fixup", true);
    Services.obs.addObserver(this, "browser-delayed-startup-finished");
    Services.obs.addObserver(this, "xpcom-shutdown");
  },

  onWindowOpen(aWindow) {
    // Listener creates ContentLinkHandler.jsm which handles link element parsing.
    let chromeListener = new EmbedLiteChromeListener(aWindow);
    this._chromeListeners[chromeListener.windowId] = chromeListener;
    this._lastCreatedWindowId = chromeListener.windowId;
    let chromeEventHandler = Services.embedlite.chromeEventHandler(aWindow);
    if (chromeEventHandler) {
      chromeEventHandler.addEventListener("DOMContentLoaded", chromeListener, false);
      chromeEventHandler.addEventListener("DOMWillOpenModalDialog", chromeListener, false);
      chromeEventHandler.addEventListener("DOMModalDialogClosed", chromeListener, false);
      chromeEventHandler.addEventListener("DOMWindowClose", chromeListener, false);
      chromeEventHandler.addEventListener("DOMMetaAdded", chromeListener, false);
      chromeEventHandler.addEventListener("DOMPopupBlocked", chromeListener, false);
    } else {
      Logger.warn("Something went wrong, could not get chrome event handler for window", aWindow, "id:", chromeListener.windowId, "when opening a window")
    }
  },

  onWindowClosed(aWindow) {
    let chromeEventHandler = Services.embedlite.chromeEventHandler(aWindow);
    let windowId = Services.embedlite.getIDByWindow(aWindow);
    let chromeListener = this._chromeListeners[windowId];
    if (chromeEventHandler) {
      chromeEventHandler.removeEventListener("DOMContentLoaded", chromeListener, false);
      chromeEventHandler.addEventListener("DOMWillOpenModalDialog", chromeListener, false);
      chromeEventHandler.addEventListener("DOMModalDialogClosed", chromeListener, false);
      chromeEventHandler.addEventListener("DOMWindowClose", chromeListener, false);
      chromeEventHandler.addEventListener("DOMMetaAdded", chromeListener, false);
    } else {
      Logger.warn("Something went wrong, could not get chrome event handler for window", aWindow, "id:", chromeListener.windowId, "when opening a window")
    }
    if (this._lastCreatedWindowId === windowId) {
      this._lastCreatedWindowId = 0;
    }
    delete this._chromeListeners[windowId];
  },

  observe(aSubject, aTopic, aData) {
    let self = this;
    switch (aTopic) {
    case "keyword-uri-fixup":
      var windowId = this._lastCreatedWindowId;
      try {
        windowId = Services.embedlite.getIDByWindow(Services.ww.activeWindow);
      } catch (e) {
        // Do nothing
      }
      if (windowId) {
        this._chromeListeners[windowId].userRequested = aData;
      } else {
        Logger.warn("JSComp: EmbedLiteChromeManager.js no window to store request against");
      }
      break;
    case "app-startup":
      self._initialize();
      break;
    case "embedliteviewcreated":
      self.onWindowOpen(aSubject);
      break;
    case "domwindowclosed":
      self.onWindowClosed(aSubject);
      break;
    case "embed-network-link-status":
      let network = JSON.parse(aData);
      Services.io.manageOfflineStatus = true;
      Services.io.offline = network.offline;
      Services.obs.notifyObservers(null, "network:link-status-changed",
                                   network.offline ? "down" : "up");
    case "browser-delayed-startup-finished":
      AboutCertViewerHandler.init();
      Services.obs.removeObserver(this, "browser-delayed-startup-finished");
      break;
    case "xpcom-shutdown":
      AboutCertViewerHandler.uninit();
      break;
    default:
      Logger.debug("EmbedLiteChromeManager subject", aSubject, "topic:", aTopic);
    }
  },

  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver, Ci.nsISupportsWeakReference])
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([EmbedLiteChromeManager]);
