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

ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
ChromeUtils.import("resource://gre/modules/Services.jsm");

XPCOMUtils.defineLazyModuleGetters(this, {
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
  this.docShell = aWindow.QueryInterface(Ci.nsIInterfaceRequestor)
                         .getInterface(Ci.nsIWebNavigation)
                         .QueryInterface(Ci.nsIDocShell);

  ContentLinkHandler.init(this);
}

EmbedLiteChromeListener.prototype = {
  targetDOMWindow: null,
  docShell: null,
  windowId: -1,

  // -------------------------------------------------------------------------
  // Added call through function to mimic chrome and satisfy ContentLinkHandler
  addEventListener(eventType, callback, options) {
    let chromeEventHandler = Services.embedlite.chromeEventHandler(this.targetDOMWindow);
    chromeEventHandler.addEventListener(eventType, callback, options);
  },

  sendAsyncMessage(messageName, message) {
    Services.embedlite.sendAsyncMessage(this.windowId, messageName, JSON.stringify(message));
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
      let doc = this.docShell.getInterface(Ci.nsIDOMDocument);
      var docURI = doc && doc.documentURI || "";
      if (!docURI.startsWith("about:blank")) {
        messageName = "chrome:contentloaded";
        message["docuri"] = docURI;
      }

      break;
   case "DOMWillOpenModalDialog":
   case "DOMModalDialogClosed":
   case "DOMWindowClose":
      messageName = "chrome:winopenclose";
      message["type"] = event.type;
      break;
    }
  },

  QueryInterface: XPCOMUtils.generateQI([Ci.nsIDOMEventListener,
                                         Ci.nsISupportsWeakReference])
};

function EmbedLiteChromeManager()
{
  Logger.debug("JSComp: EmbedLiteChromeManager.js loaded");
}

EmbedLiteChromeManager.prototype = {
  classID: Components.ID("{9d17cd12-da27-4f4c-957c-f355910ac2e9}"),
  _chromeListeners: {},

  _initialize() {
    // Use "embedliteviewcreated" instead of "domwindowopened".
    Services.obs.addObserver(this, "embedliteviewcreated", true);
    Services.obs.addObserver(this, "embed-network-link-status", true)
    Services.obs.addObserver(this, "domwindowclosed", true);
    Services.obs.addObserver(this, "xpcom-shutdown", false);
  },

  onWindowOpen(aWindow) {
    // Listener creates ContentLinkHandler.jsm which handles link element parsing.
    let chromeListener = new EmbedLiteChromeListener(aWindow);
    this._chromeListeners[aWindow] = chromeListener;
    let chromeEventHandler = Services.embedlite.chromeEventHandler(aWindow);
    if (chromeEventHandler) {
      chromeEventHandler.addEventListener("DOMContentLoaded", chromeListener, false);
      chromeEventHandler.addEventListener("DOMWillOpenModalDialog", chromeListener, false);
      chromeEventHandler.addEventListener("DOMModalDialogClosed", chromeListener, false);
      chromeEventHandler.addEventListener("DOMWindowClose", chromeListener, false);
      chromeEventHandler.addEventListener("DOMMetaAdded", chromeListener, false);
    } else {
      Logger.warn("Something went wrong, could not get chrome event handler for window", aWindow, "id:", chromeListener.windowId, "when opening a window")
    }
  },

  onWindowClosed(aWindow) {
    let chromeEventHandler = Services.embedlite.chromeEventHandler(aWindow);
    let chromeListener = this._chromeListeners[aWindow];
    if (chromeEventHandler) {
      chromeEventHandler.removeEventListener("DOMContentLoaded", chromeListener, false);
      chromeEventHandler.addEventListener("DOMWillOpenModalDialog", chromeListener, false);
      chromeEventHandler.addEventListener("DOMModalDialogClosed", chromeListener, false);
      chromeEventHandler.addEventListener("DOMWindowClose", chromeListener, false);
      chromeEventHandler.addEventListener("DOMMetaAdded", chromeListener, false);
    } else {
      Logger.warn("Something went wrong, could not get chrome event handler for window", aWindow, "id:", chromeListener.windowId, "when opening a window")
    }
  },

  observe(aSubject, aTopic, aData) {
    let self = this;
    switch (aTopic) {
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
      break;
    default:
      Logger.debug("EmbedLiteChromeManager subject", aSubject, "topic:", aTopic);
    }
  },

  QueryInterface: XPCOMUtils.generateQI([Ci.nsIObserver, Ci.nsISupportsWeakReference])
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([EmbedLiteChromeManager]);
