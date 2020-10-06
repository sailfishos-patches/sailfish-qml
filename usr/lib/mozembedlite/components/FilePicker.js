/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const Ci = Components.interfaces;
const Cu = Components.utils;
const Cc = Components.classes;

// Ported from Android FF esr52 sha1 2aba798852e4c1976f09181ceeebd68cef372cf1

Cu.import("resource://gre/modules/XPCOMUtils.jsm");
Cu.import("resource://gre/modules/Services.jsm");
Cu.import("resource://gre/modules/FileUtils.jsm");

Cu.importGlobalProperties(['File']);

XPCOMUtils.defineLazyServiceGetter(Services, "embedlite",
                                    "@mozilla.org/embedlite-app-service;1",
                                    "nsIEmbedAppService");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

function FilePicker() {
  Logger.debug("JSComp: FilePicker.js loaded");
}

FilePicker.prototype = {
  _mimeTypeFilter: 0,
  _extensionsFilter: "",
  _defaultString: "",
  _domWin: null,
  _defaultExtension: null,
  _displayDirectory: null,
  _fileItems: null,
  _promptActive: false,
  _filterIndex: 0,
  _addToRecentDocs: false,
  _title: "",

  init: function(aParent, aTitle, aMode) {
    this._domWin = aParent;
    this._mode = aMode;
    this._title = aTitle;
    Services.obs.addObserver(this, "FilePicker:Result", false);

    let idService = Cc["@mozilla.org/uuid-generator;1"].getService(Ci.nsIUUIDGenerator); 
    this.guid = idService.generateUUID().toString();

    if (aMode != Ci.nsIFilePicker.modeOpen && aMode != Ci.nsIFilePicker.modeOpenMultiple)
      throw Components.results.NS_ERROR_NOT_IMPLEMENTED;
  },

  appendFilters: function(aFilterMask) {
    if (aFilterMask & Ci.nsIFilePicker.filterAudio) {
      this._mimeTypeFilter = "audio/*";
      return;
    }

    if (aFilterMask & Ci.nsIFilePicker.filterImages) {
      this._mimeTypeFilter = "image/*";
      return;
    }

    if (aFilterMask & Ci.nsIFilePicker.filterVideo) {
      this._mimeTypeFilter = "video/*";
      return;
    }

    if (aFilterMask & Ci.nsIFilePicker.filterAll) {
      this._mimeTypeFilter = "*/*";
      return;
    }

    /* From BaseFilePicker.cpp */
    if (aFilterMask & Ci.nsIFilePicker.filterHTML) {
      this.appendFilter("*.html; *.htm; *.shtml; *.xhtml");
    }
    if (aFilterMask & Ci.nsIFilePicker.filterText) {
      this.appendFilter("*.txt; *.text");
    }

    if (aFilterMask & Ci.nsIFilePicker.filterXML) {
      this.appendFilter("*.xml");
    }

    if (aFilterMask & Ci.nsIFilePicker.xulFilter) {
      this.appendFilter("*.xul");
    }

    if (aFilterMask & Ci.nsIFilePicker.xulFilter) {
      this.appendFilter("..apps");
    }
  },

  appendFilter: function(title, filter) {
    if (this._extensionsFilter)
        this._extensionsFilter += ", ";
    this._extensionsFilter += filter;
  },

  get defaultString() {
    return this._defaultString;
  },

  set defaultString(defaultString) {
    this._defaultString = defaultString;
  },

  get defaultExtension() {
    return this._defaultExtension;
  },

  set defaultExtension(defaultExtension) {
    this._defaultExtension = defaultExtension;
  },

  get filterIndex() {
    return this._filterIndex;
  },

  set filterIndex(val) {
    this._filterIndex = val;
  },
  
  get displayDirectory() {
    return this._displayDirectory;
  },

  set displayDirectory(dir) {
    this._displayDirectory = dir;
  },

  get file() {
    if (!this._fileItems) {
        return null;
    }

    return new FileUtils.File(this._fileItems);
  },

  get fileURL() {
    let file = this.getFile();
    return Services.io.newFileURI(file);
  },

  get files() {
    return this.getEnumerator(this._fileItems, function(file) {
      return file;
    });
  },

  // We don't support directory selection yet.
  get domFileOrDirectory() {
    let f = this.file;
    if (!f) {
        return null;
    }

    let win = this._domWin;
    if (win) {
      let utils = win.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils);
      return utils.wrapDOMFile(f);
    }

    return File.createFromNsIFile(f);
  },

  get domFileOrDirectoryEnumerator() {
    let win = this._domWin;
    return this.getEnumerator(this._fileItems, function(file) {
      if (win) {
        let utils = win.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils);
        return utils.wrapDOMFile(file);
      }

      return File.createFromNsIFile(file);
    });
  },

  get addToRecentDocs() {
    return this._addToRecentDocs;
  },

  set addToRecentDocs(val) {
    this._addToRecentDocs = val;
  },

  get mode() {
    return this._mode;
  },

  show: function() {
    if (this._domWin) {
      this.fireDialogEvent(this._domWin, "DOMWillOpenModalDialog");
      let winUtils = this._domWin.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils);
      winUtils.enterModalState();
    }

    this._promptActive = true;
    this._sendMessage();

    let thread = Services.tm.currentThread;
    while (this._promptActive)
      thread.processNextEvent(true);
    delete this._promptActive;

    Services.embedlite.removeMessageListener("filepickerresponse", this);

    if (this._domWin) {
      let winUtils = this._domWin.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils);
      winUtils.leaveModalState();
      this.fireDialogEvent(this._domWin, "DOMModalDialogClosed");
    }

    if (this._fileItems)
      return Ci.nsIFilePicker.returnOK;

    return Ci.nsIFilePicker.returnCancel;
  },

  open: function(callback) {
    this._callback = callback;
    this._sendMessage();
  },

  _sendMessage: function() {
    let msg = {
      type: "embed:filepicker",
      winId: Services.embedlite.getIDByWindow(this._domWin),
      title: this._title,
      mode: this._mode
    };

    if (!this._extensionsFilter && !this._mimeTypeFilter) {
      // If neither filters is set show anything we can.
      msg.mimeType = "*/*";
    } else if (this._extensionsFilter) {
      msg.mimeType = this._extensionsFilter;
    } else {
      msg.mimeType = this._mimeTypeFilter;
    }

    this.sendMessageToEmbed(msg);
  },

  sendMessageToEmbed: function(aMsg) {
    Services.embedlite.sendAsyncMessage(aMsg.winId, aMsg.type, JSON.stringify(aMsg));
    Services.embedlite.addMessageListener("filepickerresponse", this);
  },

  onMessageReceived: function(aMessageName, aData) {
    let data = JSON.parse(aData);

    let winId = data.winId;
    let accepted = data.accepted;
    let items = data.items;

    this._fileItems = null;

    // Only store filePath if items contains data.
    if (data.items && data.items.length > 0 && data.items[0])
      this._fileItems = data.items;

    this._promptActive = false;

    if (this._callback) {
      this._callback.done(this._fileItems && accepted ? Ci.nsIFilePicker.returnOK : Ci.nsIFilePicker.returnCancel);
      Services.embedlite.removeMessageListener("filepickerresponse", this);
    }
    delete this._callback;
  },

  getEnumerator: function(files, mapFunction) {
    return {
      QueryInterface: XPCOMUtils.generateQI([Ci.nsISimpleEnumerator]),
      mFiles: files,
      mIndex: 0,
      hasMoreElements: function() {
        return (this.mIndex < this.mFiles.length);
      },
      getNext: function() {
        if (this.mIndex >= this.mFiles.length) {
          throw Components.results.NS_ERROR_FAILURE;
        }
        return mapFunction(new FileUtils.File(this.mFiles[this.mIndex++]));
      }
    };
  },

  fireDialogEvent: function(aDomWin, aEventName) {
    // accessing the document object can throw if this window no longer exists. See bug 789888.
    try {
      if (!aDomWin.document)
        return;
      let event = aDomWin.document.createEvent("Events");
      event.initEvent(aEventName, true, true);
      let winUtils = aDomWin.QueryInterface(Ci.nsIInterfaceRequestor)
                           .getInterface(Ci.nsIDOMWindowUtils);
      winUtils.dispatchEventToChromeOnly(aDomWin, event);
    } catch(ex) {
    }
  },

  classID: Components.ID("{18a4e042-7c7c-424b-a583-354e68553a7f}"),
  QueryInterface: XPCOMUtils.generateQI([Ci.nsIFilePicker, Ci.nsIEmbedMessageListener])
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([FilePicker]);
