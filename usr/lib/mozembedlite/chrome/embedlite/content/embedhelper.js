/* -*- Mode: JavaScript; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
"use strict";

let { classes: Cc, interfaces: Ci, results: Cr, utils: Cu }  = Components;
Cu.import("resource://gre/modules/XPCOMUtils.jsm");
Cu.import("resource://gre/modules/Services.jsm");
Cu.import("resource://gre/modules/Geometry.jsm");
Cu.import("resource://gre/modules/FileUtils.jsm");

Cu.importGlobalProperties(["InspectorUtils"]);

XPCOMUtils.defineLazyModuleGetter(this, "LoginManagerContent",
                                  "resource://gre/modules/LoginManagerContent.jsm");
XPCOMUtils.defineLazyModuleGetter(this, "LoginManagerParent",
                                  "resource://gre/modules/LoginManagerParent.jsm");


XPCOMUtils.defineLazyServiceGetter(Services, "embedlite",
                                    "@mozilla.org/embedlite-app-service;1",
                                    "nsIEmbedAppService");

var globalObject = null;
var gScreenWidth = 0;
var gScreenHeight = 0;

const kEmbedStateActive = 0x00000001; // :active pseudoclass for elements

function EmbedHelper() {
  this.contentDocumentIsDisplayed = true;
  // Reasonable default. Will be read from preferences.
  this.inputItemSize = 38;
  this.inputZoomed = false;
  this.zoomMargin = 14;
  this.vkbOpen = false;
  this.vkbOpenCompositionMetrics = null;
  this.inFullScreen = false;
  this._init();
}

EmbedHelper.prototype = {
  QueryInterface: XPCOMUtils.generateQI([Ci.nsIObserver,
                                         Ci.nsISupportsWeakReference]),

  _fastFind: null,
  _init: function()
  {
    Logger.debug("EmbedHelper init called");

    ViewportHandler.init();

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
    // Metrics used when virtual keyboard is open/opening.
    addMessageListener("embedui:vkbOpenCompositionMetrics", this);
    addMessageListener("embedui:addhistory", this);
    addMessageListener("Memory:Dump", this);
    addMessageListener("Gesture:ContextMenuSynth", this);
    addMessageListener("embed:ContextMenuCreate", this);
    Services.obs.addObserver(this, "embedlite-before-first-paint", true);
    Services.prefs.addObserver("embedlite.inputItemSize", this, false);
    Services.prefs.addObserver("embedlite.zoomMargin", this, false);
    this.updateInputItemSizePref();
    this.updateZoomMarginPref();
  },

  // Similar to HtmlInputElement IsExperimentalMobileType
  isExperimentalMobileType: function(type) {
      return type === "number" || type === "time" || type === "date";
  },

  getFocusedInput: function(aBrowser, aOnlyInputElements = false) {
    if (!aBrowser)
      return null;

    let doc = aBrowser.document;

    if (!doc)
      return null;

    let focused = doc.activeElement;

    while (focused instanceof content.HTMLFrameElement || focused instanceof content.HTMLIFrameElement) {
      doc = focused.contentDocument;
      focused = doc.activeElement;
    }

    if (focused instanceof content.HTMLInputElement && (focused.mozIsTextField && focused.mozIsTextField(false)
                                                        || this.isExperimentalMobileType(focused.type))) {
      return { inputElement: focused, isTextField: true };
    }

    if (aOnlyInputElements)
      return null;

    if (focused && (focused instanceof content.HTMLTextAreaElement || focused.isContentEditable)) {
      return { inputElement: focused, isTextField: false };
    }
    return { inputElement: null, isTextField: false };
  },

  scrollToFocusedInput: function() {
    let { inputElement: inputElement, isTextField: isTextField } = this.getFocusedInput(content);
    if (inputElement && this.isVirtualKeyboardOpen()) {
      let viewportMetadata = ViewportHandler.getViewportMetadata(content);
      // _zoomToInput will handle not sending any message if this input is already mostly filling the screen
      this._zoomToInput(inputElement, viewportMetadata.allowZoom, isTextField);
    }
  },

  observe: function(aSubject, aTopic, data) {
    // Ignore notifications not about our document.
    switch (aTopic) {
        case "embedlite-before-first-paint":
          // Is it on the top level?
          this.contentDocumentIsDisplayed = true;
          break;
        case "nsPref:changed":
          if (data == "embedlite.inputItemSize") {
            this.updateInputItemSizePref();
          } else if (data == "embedlite.zoomMargin") {
            this.updateZoomMarginPref();
          }

          break;
    }
  },

  _previousViewportData: null,
  _viewportData: null,
  _viewportReadyToChange: false,
  _lastTarget: null,
  _lastTargetY: 0,
  _touchEventDefaultPrevented: false,

  resetMaxLineBoxWidth: function() {
    let webNav = content.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIWebNavigation);
    let docShell = webNav.QueryInterface(Ci.nsIDocShell);
    let docViewer = docShell.contentViewer.QueryInterface(Ci.nsIMarkupDocumentViewer);
    docViewer.changeMaxLineBoxWidth(0);
  },

  updateInputItemSizePref: function() {
    try {
      let tmpSize = Services.prefs.getIntPref("embedlite.inputItemSize");
      if (tmpSize) {
        this.inputItemSize = tmpSize;
      }
    } catch (e) {} /*pref is missing*/
  },

  updateZoomMarginPref: function() {
    try {
      let tmpMargin = Services.prefs.getIntPref("embedlite.zoomMargin");
      if (tmpMargin) {
        this.zoomMargin = tmpMargin;
      }
    } catch (e) {} /*pref is missing*/
  },

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
          // scrollToFocusedInput does its own checks to find out if an element should be zoomed into
          this.scrollToFocusedInput();
        } catch(e) {
          Cu.reportError(e);
        }

        if (this._touchEventDefaultPrevented) {
          this._touchEventDefaultPrevented = false;
        } else {
          let uri = this._getLinkURI(this._touchElement);
          if (uri && (uri instanceof Ci.nsIURI)) {
            let winId = Services.embedlite.getIDByWindow(content);
            Services.embedlite.sendAsyncMessage(winId, "embed:linkclicked",
                                                JSON.stringify({
                                                                 "uri": uri.asciiSpec
                                                              }));
          }
          this._touchElement = null;
        }
        break;
      }
      case "Gesture:DoubleTap": {
        this._cancelTapHighlight();
        break;
      }
      case "Gesture:LongTap": {
        this._cancelTapHighlight();
        let element = this._touchElement;
        if (element) {
          let [x, y] = [aMessage.json.x, aMessage.json.y];
          ContextMenuHandler._processPopupNode(element, x, y, Ci.nsIDOMMouseEvent.MOZ_SOURCE_UNKNOWN);
        }
        this._touchElement = null;
        break;
      }
      case "embedui:find": {
        let searchText = aMessage.json.text;
        let searchAgain = aMessage.json.again;
        let searchBackwards = aMessage.json.backwards;
        let result = Ci.nsITypeAheadFind.FIND_NOTFOUND;
        if (!this._fastFind) {
          this._fastFind = Cc["@mozilla.org/typeaheadfind;1"].createInstance(Ci.nsITypeAheadFind);
          this._fastFind.init(docShell);
          result = this._fastFind.find(searchText, false);
        }
        else {
          if (!searchAgain) {
            result = this._fastFind.find(searchText, false);
          }
          else {
            result = this._fastFind.findAgain(searchBackwards, false);
          }
        }
        sendAsyncMessage("embed:find", { r: result });
        break;
      }
      case "Viewport:Change": {
        this._previousViewportData = this._viewportData
        this._viewportData = aMessage.data;

        if (!this.inputZoomed) {
          this.scrollToFocusedInput();
        }
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
      case "embedui:vkbOpenCompositionMetrics": {
        if (aMessage.data) {
          this.vkbOpenCompositionMetrics = aMessage.data;
          if (this.vkbOpenCompositionMetrics.imOpen) {
            gScreenWidth = this.vkbOpenCompositionMetrics.screenWidth;
            gScreenHeight = this.vkbOpenCompositionMetrics.screenHeight;
            this.scrollToFocusedInput();
          } else {
            this.inputZoomed = false;
            this.vkbOpen = false;
          }
        }
        break;
      }
      case "embedui:addhistory": {
        // aMessage.data contains: 1) list of 'links' loaded from DB, 2) current 'index'.

        let webNav = content.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIWebNavigation);
        let docShell = webNav.QueryInterface(Ci.nsIDocShell);
        let shist = webNav.sessionHistory.QueryInterface(Ci.nsISHistoryInternal);
        let ioService = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService);

        try {
          // Initially we load the current URL and that creates an unneeded entry in History -> purge it.
          webNav.sessionHistory.PurgeHistory(1);
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
            let historyEntry = Cc["@mozilla.org/browser/session-history-entry;1"].createInstance(Ci.nsISHEntry);
            historyEntry.setURI(uri);
            historyEntry.triggeringPrincipal = Services.scriptSecurityManager.createNullPrincipal({});
            shist.addEntry(historyEntry, true);
        });
        if (index < 0) {
            Logger.debug("Warning: session history entry index out of bounds:", index, " returning index 0.");
            webNav.sessionHistory.getEntryAtIndex(0, true);
            index = 0;
        } else if (index >= webNav.sessionHistory.count) {
            let lastIndex = webNav.sessionHistory.count - 1;
            Logger.debug("Warning: session history entry index out of bound:" + index + ". There are " + webNav.sessionHistory.count +
                 " item(s) in the session history. Returning index " + lastIndex);
            webNav.sessionHistory.getEntryAtIndex(lastIndex, true);
            index = lastIndex;
        } else {
            webNav.sessionHistory.getEntryAtIndex(index, true);
        }

        shist.updateIndex();

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


  _rectVisibility: function(aSourceRect, aViewportRect) {
    let vRect = aViewportRect ? aViewportRect : new Rect(this._viewportData.x,
                                                         this._viewportData.y,
                                                         this._viewportData.cssCompositedRect.width,
                                                         this._viewportData.cssCompositedRect.height);
    let overlap = vRect.intersect(aSourceRect);
    let overlapArea = overlap.width * overlap.height;
    let availHeight = Math.min(aSourceRect.width * vRect.height / vRect.width, aSourceRect.height);
    let showing = overlapArea / (aSourceRect.width * availHeight);
    return { vRect: vRect, overlap: overlap, overlapArea: overlapArea, availHeight: availHeight, showing: showing }
  },

  _zoomToInput: function(aElement, aAllowZoom = true, aIsTextField = true) {
    if (!this.vkbOpenCompositionMetrics || !this.vkbOpenCompositionMetrics.imOpen || !this._viewportData) {
      return;
    }

    // Combination of browser.js _zoomToElement and special zoom logic
    let rect = ElementTouchHelper.getBoundingContentRect(aElement);

    // Rough cssCompositionHeight as virtual keyboard is not yet raised (upper half).
    let availableHeight = gScreenHeight - this.vkbOpenCompositionMetrics.bottomMargin;
    let cssCompositionHeight = availableHeight / content.devicePixelRatio;

    let maxCssCompositionWidth = gScreenWidth / content.devicePixelRatio;
    let maxCssCompositionHeight = cssCompositionHeight;

    let currentCssCompositedHeight = this._viewportData.cssCompositedRect.height
    // Are equal if vkb is already open and content is not pinched after vkb opening. It does not
    // matter if currentCssCompositedHeight happens to match target before vkb has been opened.
    if (maxCssCompositionHeight != currentCssCompositedHeight) {
      let resolution = this._viewportData.cssPageRect.width / this._viewportData.cssCompositedRect.width;
      cssCompositionHeight = (gScreenHeight - this.vkbOpenCompositionMetrics.bottomMargin) / resolution;
    } else {
      cssCompositionHeight = currentCssCompositedHeight;
    }

    // TODO / Missing: handle maximum zoom level and respect viewport meta tag
    let scaleFactor = aIsTextField ? (this.inputItemSize / availableHeight) / (rect.h / cssCompositionHeight) : 1.0;

    let margin = this.zoomMargin / scaleFactor;
    // Calculate new css composition bounds that will be the bounds after zooming. Top-left corner is not yet moved.
    let cssCompositedRect = new Rect(this._viewportData.x,
                                    this._viewportData.y,
                                    this._viewportData.cssCompositedRect.width,
                                    cssCompositionHeight);

    let bRect = new Rect(Util.clamp(rect.x - margin, 0, this._viewportData.cssPageRect.width - rect.w),
                        Util.clamp(rect.y - margin, 0, this._viewportData.cssPageRect.height - rect.h),
                        aAllowZoom ? rect.w + 2 * margin : this._viewportData.viewport.width,
                        rect.h);

    // constrict the rect to the screen's right edge
    bRect.width = Math.min(bRect.width, (this._viewportData.cssPageRect.x + cssCompositedRect.x + this._viewportData.cssPageRect.width) - bRect.x);

    let dxLeft = rect.x - cssCompositedRect.x;
    let dxRight = cssCompositedRect.x + cssCompositedRect.width - (rect.x + rect.w);
    let dxTop = rect.y - cssCompositedRect.y;
    let dxBottom = cssCompositedRect.y + cssCompositedRect.height - (rect.y + rect.h);

    let scrollToRight = Math.abs(dxLeft) > Math.abs(dxRight);
    let scrollToBottom = Math.abs(dxTop) > Math.abs(dxBottom);

    let fixedCurrentViewport = new Rect(cssCompositedRect.x,
                                        cssCompositedRect.y,
                                        Util.clamp(cssCompositedRect.width / scaleFactor, 0, maxCssCompositionWidth),
                                        Util.clamp(cssCompositedRect.height / scaleFactor, 0, maxCssCompositionHeight));

    // We want to scale input so that it will be readable. In case we move from one input field to another or refocus
    // the same field we don't want to move input if it's already visible and of correct size.
    let halfMargin = margin / 2;
    let inputRect = new Rect(Math.abs(rect.x - halfMargin) > halfMargin ? rect.x - halfMargin : rect.x,
                             rect.y - halfMargin,
                             rect.w + halfMargin,
                             rect.h + halfMargin);

    let { showing: showing } = this._rectVisibility(inputRect, fixedCurrentViewport);

    // Adjust position based on new composition area size.
    let needXAxisMoving = this._testXMovement(inputRect, fixedCurrentViewport);
    let needYAxisMoving = this._testYMovement(inputRect, fixedCurrentViewport);

    let xUpdated = false

    // More content will be visible
    if (scaleFactor < 1.0) {
      let moveToZero = new Rect(0, fixedCurrentViewport.y, fixedCurrentViewport.width, fixedCurrentViewport.height);
      let zeroNeedsMoving = this._testXMovement(inputRect, moveToZero);
      if (!zeroNeedsMoving) {
        xUpdated = true;
        needXAxisMoving = false;
      }
    }

    if (needXAxisMoving && aIsTextField) {
      if (scrollToRight) {
        rect.x = inputRect.x + inputRect.width - fixedCurrentViewport.width;
      } else {
        let tmpX = bRect.x;
        if (rect.x > 0) {
          let moveToZero = new Rect(0, cssCompositedRect.y, cssCompositedRect.width, cssCompositedRect.height);
          needXAxisMoving = this._testXMovement(inputRect, moveToZero);
          if (!needXAxisMoving) {
            tmpX = 0;
          }
        }
        rect.x = tmpX;
      }
    } else if (!xUpdated) {
      // Visible css viewport is properly scaled
      rect.x = cssCompositedRect.x;
    }

    if (needYAxisMoving) {
      if (scrollToBottom) {
        rect.y = inputRect.y + inputRect.height - fixedCurrentViewport.height + margin;
      }
      else {
        rect.y = bRect.y;
      }
    } else {
      // Visible css viewport is properly scaled
      rect.y = cssCompositedRect.y;
    }

    rect.w = fixedCurrentViewport.width;
    rect.h = fixedCurrentViewport.height;

    // Are we really zooming.
    aAllowZoom = !Util.fuzzyEquals(rect.w, this._viewportData.cssCompositedRect.width)

    if (aAllowZoom) {
      var winId = Services.embedlite.getIDByWindow(content);
      Services.embedlite.zoomToRect(winId, rect.x, rect.y, rect.w, rect.h);
    } else {
      content.scrollTo(rect.x, rect.y);
    }
    this.inputZoomed = true;
  },

  // Move y-axis to viewport area and test if element is visible.
  _testXMovement: function(aElement, aViewport) {
    let tmpRect = new Rect(aElement.x, aViewport.y, aElement.width, aElement.height);
    let { showing: showing } = this._rectVisibility(tmpRect, aViewport);
    return showing < 0.99;
  },

  // Move x-axis to viewport area and test if element is visible.
  _testYMovement: function(aElement, aViewport) {
    let tmpRect = new Rect(aViewport.x, aElement.y, aElement.width, aElement.height);
    let { showing: showing } = this._rectVisibility(tmpRect, aViewport);
    return showing < 0.99;
  },

  _sendMouseEvent: function _sendMouseEvent(aName, window, aX, aY) {
    try {
      let cwu = window.top.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils);
      cwu.sendMouseEventToWindow(aName, aX, aY, 0, 1, 0, true, 0, Ci.nsIDOMMouseEvent.MOZ_SOURCE_TOUCH);
    } catch(e) {
      Cu.reportError(e);
    }
  },

  _sendContextMenuEvent: function _sendContextMenuEvent(aElement, aX, aY) {
    let window = aElement.ownerDocument.defaultView;
    try {
      let cwu = window.top.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils);
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
        LoginManagerContent.onDOMFormHasPassword(aEvent, win);
        break;
      }
      case "DOMAutoComplete":
      case "blur": {
        LoginManagerContent.onUsernameInput(aEvent);
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
    }
  },

  isBrowserContentDocumentDisplayed: function() {
    if (content.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils).isFirstPaint) {
      return false;
    }
    return this.contentDocumentIsDisplayed;
  },

  _handleFullScreenChanged: function(aEvent) {
    let window = aEvent.target.defaultView;
    let winId = Services.embedlite.getIDByWindow(window);
    this.inFullScreen = aEvent.target.mozFullScreen;
    Services.embedlite.sendAsyncMessage(winId, "embed:fullscreenchanged",
                                        JSON.stringify({
                                                         "fullscreen": aEvent.target.mozFullScreen
                                                       }));
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
          Services.io.QueryInterface(Ci.nsISpeculativeConnect).speculativeConnect(uri, null);
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
    if (aElement && aElement.nodeType == Ci.nsIDOMNode.ELEMENT_NODE &&
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

  isVirtualKeyboardOpen: function() {
    if (this.vkbOpen) {
      return this.vkbOpen;
    }

    if (this.vkbOpenCompositionMetrics && this.vkbOpenCompositionMetrics.imOpen &&
        this._previousViewportData && this._viewportData) {
      let oldVpWidth = this._previousViewportData.viewport.width;
      let oldVpHeight = this._previousViewportData.viewport.height;

      let vpWidth = this._viewportData.viewport.width;
      let vpHeight = this._viewportData.viewport.height;

      let scaleFactor = vpWidth / (gScreenWidth / content.devicePixelRatio);
      oldVpHeight = oldVpHeight / scaleFactor;
      vpHeight = vpHeight / scaleFactor;

      this.vkbOpen = Util.fuzzyEquals(oldVpHeight - vpHeight, this.vkbOpenCompositionMetrics.bottomMargin / 2);
      return this.vkbOpen;
    }
    return false;
  },

  virtualKeyboardHeight: function() {
    return this.isVirtualKeyboardOpen() ? (this.vkbOpenCompositionMetrics.bottomMargin / content.devicePixelRatio) : 0
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
                     .QueryInterface(Ci.nsIInterfaceRequestor)
                     .getInterface(Ci.nsIDOMWindowUtils);

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

  _dumpVkbMetrics: function() {
    Logger.debug("--------------- Vkb metrics -----------------------")
    this._dumpObject(this.vkbOpenCompositionMetrics)
    Logger.debug("--------------- Vkb metrics dumpped ---------------")
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

const ElementTouchHelper = {
  getBoundingContentRect: function(aElement) {
    if (!aElement)
      return {x: 0, y: 0, w: 0, h: 0};

    let document = aElement.ownerDocument;
    while (document.defaultView.frameElement)
      document = document.defaultView.frameElement.ownerDocument;

    let cwu = document.defaultView.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils);
    let scrollX = {}, scrollY = {};
    cwu.getScrollXY(false, scrollX, scrollY);

    let r = aElement.getBoundingClientRect();

    // step out of iframes and frames, offsetting scroll values
    for (let frame = aElement.ownerDocument.defaultView; frame.frameElement && frame != content; frame = frame.parent) {
      // adjust client coordinates' origin to be top left of iframe viewport
      let rect = frame.frameElement.getBoundingClientRect();
      let left = frame.getComputedStyle(frame.frameElement, "").borderLeftWidth;
      let top = frame.getComputedStyle(frame.frameElement, "").borderTopWidth;
      scrollX.value += rect.left + parseInt(left);
      scrollY.value += rect.top + parseInt(top);
    }

    return {x: r.left + scrollX.value,
            y: r.top + scrollY.value,
            w: r.width,
            h: r.height };
  }
};


// Blindly copied from Safari documentation for now.
const kViewportMinScale  = 0;
const kViewportMaxScale  = 10;
const kViewportMinWidth  = 200;
const kViewportMaxWidth  = 10000;
const kViewportMinHeight = 223;
const kViewportMaxHeight = 10000;

var ViewportHandler = {
  // The cached viewport metadata for each document. We tie viewport metadata to each document
  // instead of to each tab so that we don't have to update it when the document changes. Using an
  // ES6 weak map lets us avoid leaks.
  _metadata: new WeakMap(),
  _zoom: 1.0,

  init: function init() {
  },

  update: function(viewport) {
    if (viewport) {
      this._zoom = viewport.cssPageRect.width / viewport.cssCompositedRect.width;
    } else {
      Logger.debug("Updated with an invalid viewport")
    }
  },

  get zoomLevel() {
    return this._zoom;
  },

  /**
   * Returns the ViewportMetadata object.
   */
  getViewportMetadata: function getViewportMetadata(aWindow) {
    let windowUtils = aWindow.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils);

    // viewport details found here
    // http://developer.apple.com/safari/library/documentation/AppleApplications/Reference/SafariHTMLRef/Articles/MetaTags.html
    // http://developer.apple.com/safari/library/documentation/AppleApplications/Reference/SafariWebContent/UsingtheViewport/UsingtheViewport.html

    // Note: These values will be NaN if parseFloat or parseInt doesn't find a number.
    // Remember that NaN is contagious: Math.max(1, NaN) == Math.min(1, NaN) == NaN.
    let hasMetaViewport = true;
    let scale = parseFloat(windowUtils.getDocumentMetadata("viewport-initial-scale"));
    let minScale = parseFloat(windowUtils.getDocumentMetadata("viewport-minimum-scale"));
    let maxScale = parseFloat(windowUtils.getDocumentMetadata("viewport-maximum-scale"));

    let widthStr = windowUtils.getDocumentMetadata("viewport-width");
    let heightStr = windowUtils.getDocumentMetadata("viewport-height");
    let width = this.clamp(parseInt(widthStr), kViewportMinWidth, kViewportMaxWidth) || 0;
    let height = this.clamp(parseInt(heightStr), kViewportMinHeight, kViewportMaxHeight) || 0;

    // Allow zoom unless explicity disabled or minScale and maxScale are equal.
    // WebKit allows 0, "no", or "false" for viewport-user-scalable.
    // Note: NaN != NaN. Therefore if minScale and maxScale are undefined the clause has no effect.
    let allowZoomStr = windowUtils.getDocumentMetadata("viewport-user-scalable");
    let allowZoom = !/^(0|no|false)$/.test(allowZoomStr) && (minScale != maxScale);

    // Double-tap should always be disabled if allowZoom is disabled. So we initialize
    // allowDoubleTapZoom to the same value as allowZoom and have additional conditions to
    // disable it in updateViewportSize.
    let allowDoubleTapZoom = allowZoom;

    let autoSize = true;

    if (isNaN(scale) && isNaN(minScale) && isNaN(maxScale) && allowZoomStr == "" && widthStr == "" && heightStr == "") {
      // Only check for HandheldFriendly if we don't have a viewport meta tag
      let handheldFriendly = windowUtils.getDocumentMetadata("HandheldFriendly");
      if (handheldFriendly == "true") {
        return new ViewportMetadata({
          defaultZoom: 1,
          autoSize: true,
          allowZoom: true,
          allowDoubleTapZoom: false
        });
      }

      let doctype = aWindow.document.doctype;
      if (doctype && /(WAP|WML|Mobile)/.test(doctype.publicId)) {
        return new ViewportMetadata({
          defaultZoom: 1,
          autoSize: true,
          allowZoom: true,
          allowDoubleTapZoom: false
        });
      }

      hasMetaViewport = false;
    }

    scale = this.clamp(scale, kViewportMinScale, kViewportMaxScale);
    minScale = this.clamp(minScale, kViewportMinScale, kViewportMaxScale);
    maxScale = this.clamp(maxScale, (isNaN(minScale) ? kViewportMinScale : minScale), kViewportMaxScale);
    if (autoSize) {
      // If initial scale is 1.0 and width is not set, assume width=device-width
      autoSize = (widthStr == "device-width" ||
                  (!widthStr && (heightStr == "device-height" || scale == 1.0)));
    }

    let isRTL = aWindow.document.documentElement.dir == "rtl";

    return new ViewportMetadata({
      defaultZoom: scale,
      minZoom: minScale,
      maxZoom: maxScale,
      width: width,
      height: height,
      autoSize: autoSize,
      allowZoom: allowZoom,
      allowDoubleTapZoom: allowDoubleTapZoom,
      isSpecified: hasMetaViewport,
      isRTL: isRTL
    });
  },

  clamp: function(num, min, max) {
    return Math.max(min, Math.min(max, num));
  },
};

// Ported from Metro code base. SHA1 554eff3a212d474f5a883
let ContentScroll =  {
  getScrollOffset: function(aWindow) {
    let cwu = aWindow.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils);
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

/**
 * An object which represents the page's preferred viewport properties:
 *   width (int): The CSS viewport width in px.
 *   height (int): The CSS viewport height in px.
 *   defaultZoom (float): The initial scale when the page is loaded.
 *   minZoom (float): The minimum zoom level.
 *   maxZoom (float): The maximum zoom level.
 *   autoSize (boolean): Resize the CSS viewport when the window resizes.
 *   allowZoom (boolean): Let the user zoom in or out.
 *   allowDoubleTapZoom (boolean): Allow double-tap to zoom in.
 *   isSpecified (boolean): Whether the page viewport is specified or not.
 */
function ViewportMetadata(aMetadata = {}) {
  this.width = ("width" in aMetadata) ? aMetadata.width : 0;
  this.height = ("height" in aMetadata) ? aMetadata.height : 0;
  this.defaultZoom = ("defaultZoom" in aMetadata) ? aMetadata.defaultZoom : 0;
  this.minZoom = ("minZoom" in aMetadata) ? aMetadata.minZoom : 0;
  this.maxZoom = ("maxZoom" in aMetadata) ? aMetadata.maxZoom : 0;
  this.autoSize = ("autoSize" in aMetadata) ? aMetadata.autoSize : false;
  this.allowZoom = ("allowZoom" in aMetadata) ? aMetadata.allowZoom : true;
  this.allowDoubleTapZoom = ("allowDoubleTapZoom" in aMetadata) ? aMetadata.allowDoubleTapZoom : true;
  this.isSpecified = ("isSpecified" in aMetadata) ? aMetadata.isSpecified : false;
  this.isRTL = ("isRTL" in aMetadata) ? aMetadata.isRTL : false;
  Object.seal(this);
}

ViewportMetadata.prototype = {
  width: null,
  height: null,
  defaultZoom: null,
  minZoom: null,
  maxZoom: null,
  autoSize: null,
  allowZoom: null,
  allowDoubleTapZoom: null,
  isSpecified: null,
  isRTL: null,

  toString: function() {
    return "width=" + this.width
         + "; height=" + this.height
         + "; defaultZoom=" + this.defaultZoom
         + "; minZoom=" + this.minZoom
         + "; maxZoom=" + this.maxZoom
         + "; autoSize=" + this.autoSize
         + "; allowZoom=" + this.allowZoom
         + "; allowDoubleTapZoom=" + this.allowDoubleTapZoom
         + "; isSpecified=" + this.isSpecified
         + "; isRTL=" + this.isRTL;
  }
};

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");
Services.scriptloader.loadSubScript("chrome://embedlite/content/Util.js");
Services.scriptloader.loadSubScript("chrome://embedlite/content/ContextMenuHandler.js");
Services.scriptloader.loadSubScript("chrome://embedlite/content/SelectionPrototype.js");
Services.scriptloader.loadSubScript("chrome://embedlite/content/SelectionHandler.js");
Services.scriptloader.loadSubScript("chrome://embedlite/content/SelectAsyncHelper.js");


globalObject = new EmbedHelper();

Logger.debug("Frame script: embedhelper.js loaded");
