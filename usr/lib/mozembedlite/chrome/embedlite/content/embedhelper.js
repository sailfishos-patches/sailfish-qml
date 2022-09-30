/* -*- Mode: JavaScript; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
"use strict";

let { classes: Cc, interfaces: Ci, results: Cr, utils: Cu }  = Components;
const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");
ChromeUtils.import("resource://gre/modules/Geometry.jsm");
ChromeUtils.import("resource://gre/modules/FileUtils.jsm");
ChromeUtils.defineModuleGetter(
  this,
  "LoginHelper",
  "resource://gre/modules/LoginHelper.jsm"
);

let actorManagerChildAttached = false;

const CHILD_SINGLETON_ACTORS = "ChildSingletonActors";

function canInitializeActorManagerChild() {
  if (actorManagerChildAttached)
    return false;

  const { sharedData } = Services.cpmm;
  return sharedData.get(CHILD_SINGLETON_ACTORS);
}

function initializeActorManagerChild() {
  try {
    if (canInitializeActorManagerChild()) {
      const { ActorManagerChild } = ChromeUtils.import("resource://gre/modules/ActorManagerChild.jsm");
      ActorManagerChild.attach(this);
      actorManagerChildAttached = true;
    }
  } catch (e) {}
}

initializeActorManagerChild();

Cu.importGlobalProperties(["InspectorUtils"]);

XPCOMUtils.defineLazyModuleGetter(this, "LoginManagerChild",
                                  "resource://gre/modules/LoginManagerChild.jsm");
XPCOMUtils.defineLazyModuleGetter(this, "LoginManagerParent",
                                  "resource://gre/modules/LoginManagerParent.jsm");


XPCOMUtils.defineLazyServiceGetter(Services, "embedlite",
                                    "@mozilla.org/embedlite-app-service;1",
                                    "nsIEmbedAppService");

XPCOMUtils.defineLazyServiceGetter(Services, "locale",
                                    "@mozilla.org/intl/localeservice;1",
                                    "mozILocaleService");

var globalObject = null;
var gScreenWidth = 0;
var gScreenHeight = 0;

const kEmbedStateActive = 0x00000001; // :active pseudoclass for elements

const availableLocales = [
  "en-US",
  "fi",
  "ru"
];

function EmbedHelper() {
  this.contentDocumentIsDisplayed = true;
  this._init();
}

EmbedHelper.prototype = {
  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver,
                                          Ci.nsISupportsWeakReference]),

  _finder: null,
  _init: function()
  {
    Logger.debug("EmbedHelper init called");

    addEventListener("touchstart", this, false);
    addEventListener("touchmove", this, false);
    addEventListener("touchend", this, false);
    addEventListener("DOMContentLoaded", this, true);
    addEventListener("DOMFormHasPassword", this, true);
    addEventListener("DOMAutoComplete", this, true);
    addEventListener("blur", this, true);
    addEventListener("mozfullscreenchange", this, false);
    addMessageListener("Viewport:Change", this);
    addMessageListener("Gesture:DoubleTap", this);
    addMessageListener("Gesture:SingleTap", this);
    addMessageListener("Gesture:LongTap", this);
    addMessageListener("embedui:find", this);
    addMessageListener("embedui:zoomToRect", this);
    addMessageListener("embedui:scrollTo", this);
    addMessageListener("embedui:addhistory", this);
    addMessageListener("embedui:runjavascript", this);
    addMessageListener("Memory:Dump", this);
    addMessageListener("Gesture:ContextMenuSynth", this);
    addMessageListener("embed:ContextMenuCreate", this);
    Services.obs.addObserver(this, "embedlite-before-first-paint", true);
    Services.cpmm.sharedData.addEventListener("change", this);

    Logger.debug("Available locales: " + availableLocales.join(", "));
    Services.locale.availableLocales = availableLocales;
  },

  // Similar to HtmlInputElement IsExperimentalMobileType
  isExperimentalMobileType: function(type) {
      return type === "number" || type === "time" || type === "date";
  },

  observe: function(aSubject, aTopic, data) {
    // Ignore notifications not about our document.
    switch (aTopic) {
        case "embedlite-before-first-paint":
          // BrowserChildHelper notifies this when document is
          // top level content document.
          this.contentDocumentIsDisplayed = true;
          break;
        case "nsPref:changed":
          // Add preferences changing listening here.
          break;
    }
  },

  _previousViewportData: null,
  _viewportData: null,
  _viewportReadyToChange: false,
  _lastTarget: null,
  _lastTargetY: 0,
  _touchEventDefaultPrevented: false,

  _touchElement: null,

  receiveMessage: function receiveMessage(aMessage) {
    switch (aMessage.name) {
      case "Gesture:ContextMenuSynth": {
        let [x, y] = [aMessage.json.x, aMessage.json.y];
        let element = this._touchElement;
        this._sendContextMenuEvent(element, x, y);
        break;
      }
      case "Gesture:SingleTap": {
        if (SelectionHandler.isActive) {
            SelectionHandler._onSelectionCopy({xPos: aMessage.json.x, yPos: aMessage.json.y});
        }

        try {
          let [x, y] = [aMessage.json.x, aMessage.json.y];
          this._sendMouseEvent("mousemove", content, x, y);
          this._sendMouseEvent("mousedown", content, x, y);
          this._sendMouseEvent("mouseup",   content, x, y);
        } catch(e) {
          Cu.reportError(e);
        }

        if (this._touchEventDefaultPrevented) {
          this._touchEventDefaultPrevented = false;
        } else {
          let uri = this._getLinkURI(this._touchElement);
          if (uri && (uri instanceof Ci.nsIURI)) {
            try {
              let winId = Services.embedlite.getIDByWindow(content);
              Services.embedlite.sendAsyncMessage(winId, "embed:linkclicked",
                                                  JSON.stringify({
                                                                   "uri": uri.asciiSpec
                                                                 }));
            } catch (e) {
              Logger.warn("embedhelper: sending async message failed", e)
            }
          }
          this._touchElement = null;
        }
        break;
      }
      case "Gesture:DoubleTap": {
        try {
          let [x, y] = [aMessage.json.x, aMessage.json.y];
          this._sendMouseEvent("mousemove", content, x, y);
          this._sendMouseEvent("mousedown", content, x, y, 2);
          this._sendMouseEvent("mouseup",   content, x, y);
        } catch(e) {
          Cu.reportError(e);
        }
        this._cancelTapHighlight();
        break;
      }
      case "Gesture:LongTap": {
        this._cancelTapHighlight();
        let element = this._touchElement;
        if (element) {
          let [x, y] = [aMessage.json.x, aMessage.json.y];
          ContextMenuHandler._processPopupNode(element, x, y, MouseEvent.MOZ_SOURCE_UNKNOWN);
        }
        this._touchElement = null;
        break;
      }
      case "embedui:find": {
        let searchText = aMessage.json.text;
        let searchAgain = aMessage.json.again;
        let searchBackwards = aMessage.json.backwards;

        if (!searchText && this._finder) {
          this._finder.removeSelection()
          this._finder.destroy()
          Services.focus.clearFocus(content);

          this._finder = null;
          return;
        }

        let result = null;
        if (!this._finder) {
          const {Finder} = ChromeUtils.import("resource://gre/modules/Finder.jsm", {});
          this._finder = new Finder(docShell);
          result = this._finder.fastFind(searchText, false, true);
        } else if (!searchAgain) {
          result = this._finder.fastFind(searchText, false, true);
        } else {
          result = this._finder.findAgain(searchText, searchBackwards, false, true);
        }
        sendAsyncMessage("embed:find", { r: result.result });
        break;
      }
      case "Viewport:Change": {
        this._viewportData = aMessage.data;
        break;
      }
      case "embedui:zoomToRect": {
        if (aMessage.data) {
          let winId = Services.embedlite.getIDByWindow(content);
          // This is a hackish way as zoomToRect does not work if x-value has not changed or viewport has not been scaled (zoom animation).
          // Thus, we're missing animation when viewport has not been scaled.
          let scroll = this._viewportData && this._viewportData.cssCompositedRect.width === aMessage.data.width;

          if (scroll) {
            content.scrollTo(aMessage.data.x, aMessage.data.y);
          } else {
            Services.embedlite.zoomToRect(winId, aMessage.data.x, aMessage.data.y, aMessage.data.width, aMessage.data.height);
          }
        }
        break;
      }
      case "embedui:scrollTo": {
        if (aMessage.data) {
            content.scrollTo(aMessage.data.x, aMessage.data.y);
        }
        break;
      }
      case "embedui:addhistory": {
        // aMessage.data contains: 1) list of 'links' loaded from DB, 2) current 'index'.

        let docShell = content.docShell;
        let sessionHistory = docShell.QueryInterface(Ci.nsIWebNavigation).sessionHistory;
        let legacyHistory = sessionHistory.legacySHistory;
        let ioService = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService);

        try {
          // Initially we load the current URL and that creates an unneeded entry in History -> purge it.
          if (legacyHistory.count > 0) {
            legacyHistory.PurgeHistory(1);
          }
        } catch (e) {
            Logger.warn("Warning: couldn't PurgeHistory. Was it a file download?", e);
        }

        // Use same default value as there is in nsSHistory.cpp of Gecko.
        let maxEntries = 50;
        try {
          maxEntries = Services.prefs.getIntPref("browser.sessionhistory.max_entries");
        } catch (e) {
          maxEntries = 50;
        } /*pref is missing*/

        let links = aMessage.data.links;
        let itemsToRemove = Math.max(0, links.length - maxEntries);
        // Adjust index to the range max session history entries.
        let index = Math.max(0, (aMessage.data.index - itemsToRemove));
        links.splice(0, itemsToRemove);
        links.forEach(function(link) {
            let uri;
            try {
                uri = ioService.newURI(link, null, null);
            } catch (e) {
                Logger.debug("Warning: no protocol provided for uri '" + link + "'. Assuming http..." + e);
                uri = ioService.newURI("http://" + link, null, null);
            }
            let historyEntry = legacyHistory.createEntry();
            historyEntry.URI = uri;
            historyEntry.triggeringPrincipal = Services.scriptSecurityManager.getSystemPrincipal();
            legacyHistory.addEntry(historyEntry, true);
        });
        if (index < 0) {
            Logger.debug("Warning: session history entry index out of bounds:", index, " returning index 0.");
            legacyHistory.getEntryAtIndex(0);
            index = 0;
        } else if (index >= sessionHistory.count) {
            let lastIndex = sessionHistory.count - 1;
            Logger.debug("Warning: session history entry index out of bound:" + index + ". There are " + sessionHistory.count +
                 " item(s) in the session history. Returning index " + lastIndex);
            legacyHistory.getEntryAtIndex(lastIndex);
            index = lastIndex;
        } else {
            legacyHistory.getEntryAtIndex(index);
        }

        // Update index value to enable forward and backward
        legacyHistory.index = index;
        legacyHistory.updateIndex();

        let initialURI;
        try {
            initialURI = ioService.newURI(links[index], null, null);
        } catch (e) {
            Logger.debug("Warning: couldn't construct initial URI. Assuming a http:// URI is provided");
            initialURI = ioService.newURI("http://" + links[index], null, null);
        }
        docShell.setCurrentURI(initialURI);
        break;
      }
      case "embedui:runjavascript": {
        if (aMessage.data && aMessage.data.script) {
          let callbackId = aMessage.data.callbackId;
          let jsstring = aMessage.data.script;

          let promise = new Promise(function(resolve, reject) {
            try {
              let f = new content.Function(jsstring);
              let resultObject = {
                stringified: false,
                result: undefined
              }
              resultObject.result = f();
              if (typeof resultObject.result === "function") {
                reject("Error: cannot return a function.")
              } else if (typeof resultObject.result === "symbol") {
                // Special handling for Symbol type
                resultObject.result = resultObject.result.toString()
                resolve(resultObject);
              } else if (typeof resultObject.result === "boolean"
                         || typeof resultObject.result === "undefined"
                         || typeof resultObject.result === "number"
                         || typeof resultObject.result === "string") {
                resolve(resultObject);
              } else {
                resultObject.result = JSON.stringify(resultObject.result);
                resultObject.stringified = true;
                resolve(resultObject);
              }
            } catch (e) {
              reject(e.toString());
            }
          }).then(resultObject => {
                    if (callbackId >= 0) {
                      let error
                      sendAsyncMessage("embed:runjavascript", {
                                         "result": resultObject.result,
                                         "stringified": resultObject.stringified,
                                         "error": error,
                                         "callbackId": callbackId
                                       });
                    }
          }).catch(error => {
                    if (callbackId >= 0) {
                      let result
                      sendAsyncMessage("embed:runjavascript", {
                                         "result": result,
                                         "stringified": false,
                                         "error": error,
                                         "callbackId": callbackId
                                       });
                    }
          });
        }

        break;
      }

      case "Memory:Dump": {
        if (aMessage.data && aMessage.data.fileName) {
            let memDumper = Cc["@mozilla.org/memory-info-dumper;1"].getService(Ci.nsIMemoryInfoDumper);
            memDumper.dumpMemoryReportsToNamedFile(aMessage.data.fileName, null, null, false);
        }
        break;
      }
      default: {
        Logger.debug("Child Script: Message: name:", aMessage.name, "json:", JSON.stringify(aMessage.json));
        break;
      }
    }
  },

  _sendMouseEvent: function _sendMouseEvent(aName, window, aX, aY, aClicks = 1) {
    try {
      let cwu = window.windowUtils;
      cwu.sendMouseEventToWindow(aName, aX, aY, 0, aClicks, 0, false, 0, MouseEvent.MOZ_SOURCE_TOUCH);
    } catch(e) {
      Cu.reportError(e);
    }
  },

  _sendContextMenuEvent: function _sendContextMenuEvent(aElement, aX, aY) {
    let window = aElement.ownerDocument.defaultView;
    try {
      let cwu = window.windowUtils;
      cwu.sendMouseEventToWindow("contextmenu", aX, aY, 2, 1, 0, false);
    } catch(e) {
      Cu.reportError(e);
    }
  },

  handleEvent: function(aEvent) {
    switch (aEvent.type) {
      case "DOMFormHasPassword": {
        let form = aEvent.target;
        let doc = form.ownerDocument;
        let win = doc.defaultView;
        LoginManagerChild.forWindow(win).onDOMFormHasPassword(aEvent);
        break;
      }
      case "DOMAutoComplete":
      case "blur": {
        let form = aEvent.target;
        if (form.ownerDocument &&
                ChromeUtils.getClassName(form) === "HTMLInputElement" &&
                (form.hasBeenTypePassword ||
                  LoginHelper.isUsernameFieldType(form))) {
          let win = form.ownerDocument.defaultView;
          LoginManagerChild.forWindow(win).onFieldAutoComplete(form, null);
        }
        break;
      }
      case 'touchstart':
        this._handleTouchStart(aEvent);
        break;
      case 'touchmove':
        this._handleTouchMove(aEvent);
        break;
      case 'touchend':
        this._handleTouchEnd(aEvent);
        break;
      case "mozfullscreenchange":
        this._handleFullScreenChanged(aEvent);
        break;
      case "change":
        // ActorManagerParent.jsm sets data and SharedMap triggers broadcasting
        // upon KeyChanged. See EmbedLiteGlobalHelper where we flush().
        if (aEvent.changedKeys.includes("ChildSingletonActors")) {
          initializeActorManagerChild();
        }
        break;
    }
  },

  isBrowserContentDocumentDisplayed: function() {
    if (content.windowUtils.isFirstPaint) {
      return false;
    }
    return this.contentDocumentIsDisplayed;
  },

  _handleFullScreenChanged: function(aEvent) {
    let window = aEvent.target.ownerDocument.defaultView;
    try {
      let winId = Services.embedlite.getIDByWindow(window);
      Services.embedlite.sendAsyncMessage(winId, "embed:fullscreenchanged",
                                          JSON.stringify({
                                                           "fullscreen": aEvent.target.ownerDocument.mozFullScreen
                                                         }));
    } catch (e) {
      Logger.warn("emhedhelper: sending async message failed", e)
    }
  },

  _handleTouchMove: function(aEvent) {
    this._cancelTapHighlight();
  },

  _handleTouchEnd: function(aEvent) {
    this._viewportReadyToChange = true;
    this._touchEventDefaultPrevented = (this._touchEventDefaultPrevented || aEvent.defaultPrevented);

    // Can only trigger if we have not seen touch moves i.e. we do have highlight element. Touch move
    // cancels tap highlight and also here we call cancel tap highlight at the end.
    let target = this._highlightElement;
    if (target && !this._touchEventDefaultPrevented) {
      let uri = this._getLinkURI(target);
      if (uri) {
        try {
          Services.io.speculativeConnect(uri, aEvent.target.nodePrincipal, null);
        } catch (e) {
          Logger.warn("Speculative connection error:", e)
        }
      }
    }

    this._cancelTapHighlight();
  },

  _handleTouchStart: function(aEvent) {
    if (this._touchElement) { // TODO: check if _highlightelement is enough and this can be dropped
      this._touchElement = null;
    }

    this._touchEventDefaultPrevented = aEvent.defaultPrevented;

    if (!this.isBrowserContentDocumentDisplayed() || aEvent.touches.length > 1 || aEvent.defaultPrevented)
      return;

    let target = aEvent.target;
    if (!target) {
      return;
    }

    this._doTapHighlight(target);
  },

  _getLinkURI: function(aElement) {
    if (aElement && aElement.nodeType == content.Node.ELEMENT_NODE &&
        ((ChromeUtils.getClassName(aElement) === "HTMLAnchorElement" && aElement.href) ||
         (ChromeUtils.getClassName(aElement) === "HTMLAreaElement" && aElement.href))) {
      try {
        return Services.io.newURI(aElement.href, null, null);
      } catch (e) {}
    }
    return null;
  },

  _doTapHighlight: function _doTapHighlight(aElement) {
    InspectorUtils.setContentState(aElement, kEmbedStateActive);
    this._highlightElement = aElement;
    this._touchElement = aElement;
  },

  _cancelTapHighlight: function _cancelTapHighlight() {
    if (!this._highlightElement)
      return;

    // If the active element is in a sub-frame, we need to make that frame's document
    // active to remove the element's active state.
    if (this._highlightElement.ownerDocument != content.document)
      InspectorUtils.removeContentState(this._highlightElement.ownerDocument.documentElement, kEmbedStateActive);

    InspectorUtils.removeContentState(content.document.documentElement, kEmbedStateActive);
    this._highlightElement = null;
  },

  /******************************************************
   * General utilities
   */

  /*
   * Retrieve the total offset from the window's origin to the sub frame
   * element including frame and scroll offsets. The resulting offset is
   * such that:
   * sub frame coords + offset = root frame position
   */
  getCurrentWindowAndOffset: function(x, y) {
    // If the element at the given point belongs to another document (such
    // as an iframe's subdocument), the element in the calling document's
    // DOM (e.g. the iframe) is returned.
    let utils = Util.getWindowUtils(content);
    let element = utils.elementFromPoint(x, y, true, false);
    let offset = { x:0, y:0 };

    while (element && (element instanceof content.HTMLIFrameElement ||
                       element instanceof content.HTMLFrameElement)) {
      // get the child frame position in client coordinates
      let rect = element.getBoundingClientRect();

      // calculate offsets for digging down into sub frames
      // using elementFromPoint:

      // Get the content scroll offset in the child frame
      let scrollOffset = ContentScroll.getScrollOffset(element.contentDocument.defaultView);
      // subtract frame and scroll offset from our elementFromPoint coordinates
      x -= rect.left + scrollOffset.x;
      y -= rect.top + scrollOffset.y;

      // calculate offsets we'll use to translate to client coords:

      // add frame client offset to our total offset result
      offset.x += rect.left;
      offset.y += rect.top;

      // get the frame's nsIDOMWindowUtils
      utils = element.contentDocument
                     .defaultView
                     .windowUtils;

      // retrieve the target element in the sub frame at x, y
      element = utils.elementFromPoint(x, y, true, false);
    }

    if (!element)
      return {};

    return {
      element: element,
      contentWindow: element.ownerDocument.defaultView,
      offset: offset,
      utils: utils
    };
  },

  _dumpViewport: function() {
    Logger.debug("--------------- Viewport data -----------------------")
    this._dumpObject(this._viewportData)
    Logger.debug("--------------- Viewport data dumpped ---------------")
  },

  _dumpObject: function(object) {
    if (object) {
      for (var i in object) {
        if (typeof(object[i]) == "object") {
          for (var j in object[i]) {
            Logger.debug("   ", i, j, ":", object[i][j])
          }
        } else {
          Logger.debug(i, ":", object[i])
        }
      }
    } else {
      Logger.debug("Nothing to dump")
    }
  }
};

// Ported from Metro code base. SHA1 554eff3a212d474f5a883
let ContentScroll =  {
  getScrollOffset: function(aWindow) {
    let cwu = aWindow.windowUtils;
    let scrollX = {}, scrollY = {};
    cwu.getScrollXY(false, scrollX, scrollY);
    return { x: scrollX.value, y: scrollY.value };
  },

  getScrollOffsetForElement: function(aElement) {
    if (aElement.parentNode == aElement.ownerDocument)
      return this.getScrollOffset(aElement.ownerDocument.defaultView);
    return { x: aElement.scrollLeft, y: aElement.scrollTop };
  }
};
this.ContentScroll = ContentScroll;

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js", this);
Services.scriptloader.loadSubScript("chrome://embedlite/content/Util.js", this);
Services.scriptloader.loadSubScript("chrome://embedlite/content/ContextMenuHandler.js", this);
Services.scriptloader.loadSubScript("chrome://embedlite/content/SelectionPrototype.js", this);
Services.scriptloader.loadSubScript("chrome://embedlite/content/SelectionHandler.js", this);
Services.scriptloader.loadSubScript("chrome://embedlite/content/SelectAsyncHelper.js", this);
Services.scriptloader.loadSubScript("chrome://embedlite/content/FormAssistant.js", this);
Services.scriptloader.loadSubScript("chrome://embedlite/content/InputMethodHandler.js", this);

globalObject = new EmbedHelper();

Logger.debug("Frame script: embedhelper.js loaded");
