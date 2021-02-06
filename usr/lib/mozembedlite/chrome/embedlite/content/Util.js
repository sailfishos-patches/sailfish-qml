/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

let Util = {
  /*
   * General purpose utilities
   */
  getWindowUtils: function getWindowUtils(aWindow) {
    return aWindow.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils);
  },

  fuzzyEquals: function fuzzyEquals(a, b) {
    return (Math.abs(a - b) < 0.999);
  },

  // Recursively find all documents, including root document.
  getAllDocuments: function getAllDocuments(doc, resultSoFar) {
    resultSoFar = resultSoFar || [doc];
    if (!doc.defaultView)
      return resultSoFar;
    let frames = doc.defaultView.frames;
    if (!frames)
      return resultSoFar;

    let i;
    let currentDoc;
    for (i = 0; i < frames.length; i++) {
      currentDoc = frames[i].document;
      resultSoFar.push(currentDoc);
      this.getAllDocuments(currentDoc, resultSoFar);
    }

    return resultSoFar;
  },

  // Put the Mozilla networking code into a state that will kick the
  // auto-connection process.
  forceOnline: function forceOnline() {
    Services.io.offline = false;
  },

  // Pass several objects in and it will combine them all into the first object and return it.
  // NOTE: Deep copy is not supported
  extend: function extend() {
    // copy reference to target object
    let target = arguments[0] || {};
    let length = arguments.length;

    if (length === 1) {
      return target;
    }

    // Handle case when target is a string or something
    if (typeof target != "object" && typeof target != "function") {
      target = {};
    }

    for (let i = 1; i < length; i++) {
      // Only deal with non-null/undefined values
      let options = arguments[i];
      if (options != null) {
        // Extend the base object
        for (let name in options) {
          let copy = options[name];

          // Prevent never-ending loop
          if (target === copy)
            continue;

          if (copy !== undefined)
            target[name] = copy;
        }
      }
    }

    // Return the modified object
    return target;
  },

  /*
   * Timing utilties
   */

  // Executes aFunc after other events have been processed.
  executeSoon: function executeSoon(aFunc) {
    Services.tm.mainThread.dispatch({
      run: function() {
        aFunc();
      }
    }, Ci.nsIThread.DISPATCH_NORMAL);
  },

  dumpElement: function dumpElement(aElement) {
    Logger.debug(aElement.id);
  },

  dumpElementTree: function dumpElementTree(aElement) {
    let node = aElement;
    while (node) {
      Logger.debug("node:", node, "id:", node.id, "class:", node.classList);
      node = node.parentNode;
    }
  },

  /*
   * Element utilities
   */

  highlightElement: function highlightElement(aElement) {
    if (aElement == null) {
      Logger.debug("aElement is null");
      return;
    }
    aElement.style.border = "2px solid red";
  },

  transitionElementVisibility: function(aNodes, aVisible) {
    // accept single node or a collection of nodes
    aNodes = aNodes.length ? aNodes : [aNodes];
    let defd = Promise.defer();
    let pending = 0;
    Array.forEach(aNodes, function(aNode) {
      if (aVisible) {
        aNode.hidden = false;
        aNode.removeAttribute("fade"); // trigger transition to full opacity
      } else {
        aNode.setAttribute("fade", true); // trigger transition to 0 opacity
      }
      aNode.addEventListener("transitionend", function onTransitionEnd(aEvent){
        aNode.removeEventListener("transitionend", onTransitionEnd);
        if (!aVisible) {
          aNode.hidden = true;
        }
        pending--;
        if (!pending){
          defd.resolve(true);
        }
      }, false);
      pending++;
    });
    return defd.promise;
  },

  getHrefForElement: function getHrefForElement(target) {
    let link = null;
    while (target) {
      if (this.isLink(target) && target.hasAttribute("href")) {
        link = target;
      }
      target = target.parentNode;
    }

    if (link && link.hasAttribute("href"))
      return link.href;
    else
      return null;
  },

  isTextInput: function isTextInput(aElement) {
    return ((aElement instanceof content.HTMLInputElement &&
             aElement.mozIsTextField(false)) ||
            aElement instanceof content.HTMLTextAreaElement);
  },

  /**
   * Checks whether aElement's content can be edited either if it(or any of its
   * parents) has "contenteditable" attribute set to "true" or aElement's
   * ownerDocument is in design mode.
   */
  isEditableContent: function isEditableContent(aElement) {
    return !!aElement && (aElement.isContentEditable ||
                          this.isOwnerDocumentInDesignMode(aElement));

  },

  isEditable: function isEditable(aElement) {
    if (!aElement) {
      return false;
    }

    if (this.isTextInput(aElement) || this.isEditableContent(aElement)) {
      return true;
    }

    // If a body element is editable and the body is the child of an
    // iframe or div we can assume this is an advanced HTML editor
    if ((aElement instanceof content.HTMLIFrameElement ||
         ChromeUtils.getClassName(aElement) === "HTMLDivElement") &&
        aElement.contentDocument &&
        this.isEditableContent(aElement.contentDocument.body)) {
      return true;
    }

    return false;
  },

  /**
   * Checks whether aElement's owner document has design mode turned on.
   */
  isOwnerDocumentInDesignMode: function(aElement) {
    return !!aElement && !!aElement.ownerDocument &&
           aElement.ownerDocument.designMode == "on";
  },

  isMultilineInput: function isMultilineInput(aElement) {
    return (aElement instanceof content.HTMLTextAreaElement);
  },

  isLink: function isLink(aNode) {
    return ((aNode instanceof content.HTMLAnchorElement && aNode.href) ||
            (aNode instanceof content.HTMLAreaElement && aNode.href) ||
            aNode instanceof content.HTMLLinkElement);
  },

  isText: function isText(aElement) {
    let className = ChromeUtils.getClassName(aElement)
    return (className === "HTMLParagraphElement" ||
            className === "HTMLLIElement" ||
            className === "HTMLPreElement" ||
            aElement instanceof content.HTMLBodyElement ||
            className === "HTMLDivElement" ||
            className === "HTMLHeadingElement" ||
            className === "HTMLTableCellElement");
  },

  isMedia: function isMedia(aElement) {
    return (aElement instanceof content.HTMLMediaElement ||
            ChromeUtils.getClassName(aElement) === "HTMLVideoElement" ||
            aElement.getAttribute("playable") == "true")
  },

  /*
   * Rect and nsIDOMRect utilities
   */

  getCleanRect: function getCleanRect() {
    return {
      left: 0, top: 0, right: 0, bottom: 0
    };
  },

  pointWithinRect: function pointWithinRect(aX, aY, aRect) {
    return (aRect.left < aX && aRect.top < aY &&
            aRect.right > aX && aRect.bottom > aY);
  },

  pointWithinDOMRect: function pointWithinDOMRect(aX, aY, aRect) {
    if (!aRect.width || !aRect.height)
      return false;
    return this.pointWithinRect(aX, aY, aRect);
  },

  isEmptyDOMRect: function isEmptyDOMRect(aRect) {
    if ((aRect.bottom - aRect.top) <= 0 &&
        (aRect.right - aRect.left) <= 0)
      return true;
    return false;
  },

  // Dumps the details of a dom rect to the console
  dumpDOMRect: function dumpDOMRect(aMsg, aRect) {
    try {
      Logger.debug(aMsg,
                  "left:" + Math.round(aRect.left) + ",",
                  "top:" + Math.round(aRect.top) + ",",
                  "right:" + Math.round(aRect.right) + ",",
                  "bottom:" + Math.round(aRect.bottom) + ",",
                  "width:" + Math.round(aRect.right - aRect.left) + ",",
                  "height:" + Math.round(aRect.bottom - aRect.top) );
    } catch (ex) {
      Logger.debug("dumpDOMRect:", ex.message);
    }
  },

  /*
   * URIs and schemes
   */

  makeURI: function makeURI(aURL, aOriginCharset, aBaseURI) {
    return Services.io.newURI(aURL, aOriginCharset, aBaseURI);
  },

  makeURLAbsolute: function makeURLAbsolute(base, url) {
    // Note:  makeURI() will throw if url is not a valid URI
    return this.makeURI(url, null, this.makeURI(base)).spec;
  },

  isLocalScheme: function isLocalScheme(aURL) {
    return ((aURL.indexOf("about:") == 0 &&
             aURL != "about:blank" &&
             aURL != "about:empty" &&
             aURL != "about:start") ||
            aURL.indexOf("chrome:") == 0);
  },

  isOpenableScheme: function isShareableScheme(aProtocol) {
    let dontOpen = /^(mailto|javascript|news|snews)$/;
    return (aProtocol && !dontOpen.test(aProtocol));
  },

  isShareableScheme: function isShareableScheme(aProtocol) {
    let dontShare = /^(chrome|about|file|javascript|resource)$/;
    return (aProtocol && !dontShare.test(aProtocol));
  },

  // Don't display anything in the urlbar for these special URIs.
  isURLEmpty: function isURLEmpty(aURL) {
    return (!aURL ||
            aURL == "about:blank" ||
            aURL == "about:empty" ||
            aURL == "about:home" ||
            aURL == "about:start");
  },

  // Title to use for emptyURL tabs.
  getEmptyURLTabTitle: function getEmptyURLTabTitle() {
    let browserStrings = Services.strings.createBundle("chrome://browser/locale/browser.properties");

    return browserStrings.GetStringFromName("tabs.emptyTabTitle");
  },

  // Don't remember these pages in the session store.
  isURLMemorable: function isURLMemorable(aURL) {
    return !(aURL == "about:blank" ||
             aURL == "about:empty" ||
             aURL == "about:start");
  },

  /*
   * Math utilities
   */

  clamp: function(num, min, max) {
    return Math.max(min, Math.min(max, num));
  },

  /*
   * Screen and layout utilities
   */

   /*
    * translateToTopLevelWindow - Given an element potentially within
    * a subframe, calculate the offsets up to the top level browser.
    */
  translateToTopLevelWindow: function translateToTopLevelWindow(aElement) {
    let offsetX = 0;
    let offsetY = 0;
    let element = aElement;
    while (element &&
           element.ownerDocument &&
           element.ownerDocument.defaultView != content) {
      element = element.ownerDocument.defaultView.frameElement;
      let rect = element.getBoundingClientRect();
      offsetX += rect.left;
      offsetY += rect.top;
    }
    let win = null;
    if (element == aElement)
      win = content;
    else
      win = element.contentDocument.defaultView;
    return { targetWindow: win, offsetX: offsetX, offsetY: offsetY };
  },

  get displayDPI() {
    delete this.displayDPI;
    return this.displayDPI = this.getWindowUtils(window).displayDPI;
  },

  isPortrait: function isPortrait() {
    return (window.innerWidth <= window.innerHeight);
  },

  LOCALE_DIR_RTL: -1,
  LOCALE_DIR_LTR: 1,
  get localeDir() {
    // determine browser dir first to know which direction to snap to
    let chromeReg = Cc["@mozilla.org/chrome/chrome-registry;1"].getService(Ci.nsIXULChromeRegistry);
    return chromeReg.isLocaleRTL("global") ? this.LOCALE_DIR_RTL : this.LOCALE_DIR_LTR;
  },

  /*
   * Process utilities
   */

  isParentProcess: function isInParentProcess() {
    let appInfo = Cc["@mozilla.org/xre/app-info;1"];
    return (!appInfo || appInfo.getService(Ci.nsIXULRuntime).processType == Ci.nsIXULRuntime.PROCESS_TYPE_DEFAULT);
  },

  /*
   * Event utilities
   */

  modifierMaskFromEvent: function modifierMaskFromEvent(aEvent) {
    return (aEvent.altKey   ? Ci.nsIDOMEvent.ALT_MASK     : 0) |
           (aEvent.ctrlKey  ? Ci.nsIDOMEvent.CONTROL_MASK : 0) |
           (aEvent.shiftKey ? Ci.nsIDOMEvent.SHIFT_MASK   : 0) |
           (aEvent.metaKey  ? Ci.nsIDOMEvent.META_MASK    : 0);
  },

  /*
   * Download utilities
   */

  insertDownload: function insertDownload(aSrcUri, aFile) {
    let dm = Cc["@mozilla.org/download-manager;1"].getService(Ci.nsIDownloadManager);
    let db = dm.DBConnection;

    let stmt = db.createStatement(
      "INSERT INTO moz_downloads (name, source, target, startTime, endTime, state, referrer) " +
      "VALUES (:name, :source, :target, :startTime, :endTime, :state, :referrer)"
    );

    stmt.params.name = aFile.leafName;
    stmt.params.source = aSrcUri.spec;
    stmt.params.target = aFile.path;
    stmt.params.startTime = Date.now() * 1000;
    stmt.params.endTime = Date.now() * 1000;
    stmt.params.state = Ci.nsIDownloadManager.DOWNLOAD_NOTSTARTED;
    stmt.params.referrer = aSrcUri.spec;

    stmt.execute();
    stmt.finalize();

    let newItemId = db.lastInsertRowID;
    let download = dm.getDownload(newItemId);
    //dm.resumeDownload(download);
    //Services.obs.notifyObservers(download, "dl-start", null);
  },


  /*
   * aViewHeight - the height of the viewable area in the browser
   * aRect - a bounding rectangle of a selection or element.
   *
   * return - number of pixels for the browser to be shifted up by such
   * that aRect is centered vertically within aViewHeight.
   */
  centerElementInView: function centerElementInView(aViewHeight, aRect) {
    // If the bottom of the target bounds is higher than the new height,
    // there's no need to adjust. It will be above the keyboard.
    if (aRect.bottom <= aViewHeight) {
      return 0;
    }

    // height of the target element
    let targetHeight = aRect.bottom - aRect.top;
    // height of the browser view.
    let viewBottom = content.innerHeight;

    // If the target is shorter than the new content height, we can go ahead
    // and center it.
    if (targetHeight <= aViewHeight) {
      // Try to center the element vertically in the new content area, but
      // don't position such that the bottom of the browser view moves above
      // the top of the chrome. We purposely do not resize the browser window
      // by making it taller when trying to center elements that are near the
      // lower bounds. This would trigger reflow which can cause content to
      // shift around.
      let splitMargin = Math.round((aViewHeight - targetHeight) * .5);
      let distanceToPageBounds = viewBottom - aRect.bottom;
      let distanceFromChromeTop = aRect.bottom - aViewHeight;
      let distanceToCenter =
        distanceFromChromeTop + Math.min(distanceToPageBounds, splitMargin);
      return distanceToCenter;
    }
  },

  /*
   * Local system utilities
   */

  copyImageToClipboard: function Util_copyImageToClipboard(aImageLoadingContent) {
    let image = aImageLoadingContent.QueryInterface(Ci.nsIImageLoadingContent);
    if (!image) {
      Logger.debug("copyImageToClipboard error: image is not an nsIImageLoadingContent");
      return;
    }
    try {
      let xferable = Cc["@mozilla.org/widget/transferable;1"].createInstance(Ci.nsITransferable);
      xferable.init(null);
      let imgRequest = aImageLoadingContent.getRequest(Ci.nsIImageLoadingContent.CURRENT_REQUEST);
      let mimeType = imgRequest.mimeType;
      let imgContainer = imgRequest.image;
      let imgPtr = Cc["@mozilla.org/supports-interface-pointer;1"].createInstance(Ci.nsISupportsInterfacePointer);
      imgPtr.data = imgContainer;
      xferable.setTransferData(mimeType, imgPtr, null);
      let clip = Cc["@mozilla.org/widget/clipboard;1"].getService(Ci.nsIClipboard);
      clip.setData(xferable, null, Ci.nsIClipboard.kGlobalClipboard);
    } catch (e) {
      Logger.log(e.message);
    }
  },

  // ----------------------
  // DumpDOM(node)
  //
  // Call this function to dump the contents of the DOM starting at the specified node.
  // Use node = document.documentElement to dump every element of the current document.
  // Use node = top.window.document.documentElement to dump every element.
  //
  // 8-13-99 Updated to dump almost all attributes of every node. There are still some attributes
  //         that are purposely skipped to make it more readable.
  // ----------------------
  dumpDOM: function(node) {
    Logger.warn("--------------------- DumpDOM ---------------------");
    this.dumpNodeAndChildren(node, "");
    Logger.warn("------------------- End DumpDOM -------------------");
  },


  // This function does the work of DumpDOM by recursively calling itself to explore the tree
  dumpNodeAndChildren: function(node, prefix) {
    dump(prefix + "<" + node.nodeName);

    var attributes = node.attributes;
    if (attributes && attributes.length) {
      var item, name, value;

      for (var index = 0; index < attributes.length; index++) {
        item = attributes.item(index);
        name = item.nodeName;
        value = item.nodeValue;

        if ((name == 'lazycontent' && value == 'true') ||
            (name == 'xulcontentsgenerated' && value == 'true') ||
            (name == 'id') ||
            (name == 'instanceOf')) {
          // ignore these
        } else {
          dump(" " + name + "=\"" + value + "\"");
        }
      }
    }

    if (node.nodeType == 1) {
      // id
      var text = node.getAttribute('id');
      if ( text && text[0] != '$' )
        dump(" id=\"" + text + "\"");
    }

    if (node.nodeType == Node.TEXT_NODE)
      dump(" = \"" + node.data + "\"");

    dump(">\n");

    // dump IFRAME && FRAME DOM
    if (node.nodeName == "IFRAME" || node.nodeName == "FRAME") {
      if (node.name) {
        var wind = top.frames[node.name];
        if ( wind && wind.document && wind.document.documentElement )
        {
          dump(prefix + "----------- " + node.nodeName + " -----------\n");
          this.dumpNodeAndChildren(wind.document.documentElement, prefix + "  ");
          dump(prefix + "--------- End " + node.nodeName + " ---------\n");
        }
      }
    }
    // children of nodes (other than frames)
    else if ( node.childNodes ) {
      for ( var child = 0; child < node.childNodes.length; child++ )
        this.dumpNodeAndChildren(node.childNodes[child], prefix + "  ");
    }
  }
};


/*
 * Timeout
 *
 * Helper class to nsITimer that adds a little more pizazz.  Callback can be an
 * object with a notify method or a function.
 */
Util.Timeout = function(aCallback) {
  this._callback = aCallback;
  this._timer = Cc["@mozilla.org/timer;1"].createInstance(Ci.nsITimer);
  this._type = null;
};

Util.Timeout.prototype = {
  // Timer callback. Don't call this manually.
  notify: function notify() {
    if (this._type == this._timer.TYPE_ONE_SHOT)
      this._type = null;

    if (this._callback.notify)
      this._callback.notify();
    else
      this._callback.apply(null);
  },

  // Helper function for once and interval.
  _start: function _start(aDelay, aType, aCallback) {
    if (aCallback)
      this._callback = aCallback;
    this.clear();
    this._timer.initWithCallback(this, aDelay, aType);
    this._type = aType;
    return this;
  },

  // Do the callback once.  Cancels other timeouts on this object.
  once: function once(aDelay, aCallback) {
    return this._start(aDelay, this._timer.TYPE_ONE_SHOT, aCallback);
  },

  // Do the callback every aDelay msecs. Cancels other timeouts on this object.
  interval: function interval(aDelay, aCallback) {
    return this._start(aDelay, this._timer.TYPE_REPEATING_SLACK, aCallback);
  },

  // Clear any pending timeouts.
  clear: function clear() {
    if (this.isPending()) {
      this._timer.cancel();
      this._type = null;
    }
    return this;
  },

  // If there is a pending timeout, call it and cancel the timeout.
  flush: function flush() {
    if (this.isPending()) {
      this.notify();
      this.clear();
    }
    return this;
  },

  // Return true if we are waiting for a callback.
  isPending: function isPending() {
    return this._type !== null;
  }
};
