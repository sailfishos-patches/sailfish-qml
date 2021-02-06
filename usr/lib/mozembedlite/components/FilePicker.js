/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// Ported from Android FF esr60 sha1 c714053d73ac408ab402bb4d7e906e718f4ecb7e

ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
ChromeUtils.import("resource://gre/modules/Services.jsm");
ChromeUtils.import("resource://gre/modules/FileUtils.jsm");

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
  _domFiles: [],
  _defaultExtension: null,
  _displayDirectory: null,
  _displaySpecialDirectory: null,
  _filePath: null,
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
      throw Cr.NS_ERROR_NOT_IMPLEMENTED;
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

  get displaySpecialDirectory() {
    return this._displaySpecialDirectory;
  },

  set displaySpecialDirectory(dir) {
    this._displaySpecialDirectory = dir;
  },

  get file() {
    if (!this._filePath) {
        return null;
    }

    return new FileUtils.File(this._filePath);
  },

  get fileURL() {
    let file = this.getFile();
    return Services.io.newFileURI(file);
  },

  get files() {
    return this.getEnumerator(this._filePath);
  },

  // We don't support directory selection yet.
  get domFileOrDirectory() {
    return this._domFiles.length > 0 ? this._domFiles[0] : null;
  },

  get domFileOrDirectoryEnumerator() {
    return this.getEnumerator(this._domFiles);
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

    Services.tm.spinEventLoopUntil(() => !this._promptActive);
    delete this._promptActive;

    Services.embedlite.removeMessageListener("filepickerresponse", this);

    if (this._domWin) {
      let winUtils = this._domWin.QueryInterface(Ci.nsIInterfaceRequestor).getInterface(Ci.nsIDOMWindowUtils);
      winUtils.leaveModalState();
      this.fireDialogEvent(this._domWin, "DOMModalDialogClosed");
    }

    if (this._filePath)
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
    let accepted = data.accepted;

    this._filePath = null;
    this._domFiles = []

    // Only store filePath if items contains data.
    if (data.items && data.items.length > 0 && data.items[0])
      this._filePath = data.items;

    this._promptActive = false;

    if (!this._filePath) {
      return;
    }

    let enumerator = this.files;
    while (enumerator.hasMoreElements()) {
      let file = new FileUtils.File(enumerator.getNext());
      let promise = null;
      if (this._domWin) {
        promise = this._domWin.File.createFromNsIFile(file, { existenceCheck: false });
      } else {
        promise = File.createFromNsIFile(file, { existenceCheck: false });
      }

      promise.then(domFile => {
                     this._domFiles.push(domFile);
                     if (this._callback && (this._domFiles.length === this._filePath.length)) {
                       this._callback.done(this._filePath && accepted ?
                                             Ci.nsIFilePicker.returnOK : Ci.nsIFilePicker.returnCancel);
                       Services.embedlite.removeMessageListener("filepickerresponse", this);
                       delete this._callback;
                     }
                   }, Cu.reportError);
    }
  },

  getEnumerator: function(files) {
    return {
      QueryInterface: XPCOMUtils.generateQI([Ci.nsISimpleEnumerator]),
      mFiles: files,
      mIndex: 0,
      hasMoreElements: function() {
        return (this.mIndex < this.mFiles.length);
      },
      getNext: function() {
        if (this.mIndex >= this.mFiles.length) {
          throw Cr.NS_ERROR_FAILURE;
        }
        return this.mFiles[this.mIndex++];
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
