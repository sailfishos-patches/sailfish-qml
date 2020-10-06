/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cr = Components.results;
const Cu = Components.utils;

Cu.import("resource://gre/modules/XPCOMUtils.jsm");
Cu.import("resource://gre/modules/Services.jsm");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

function EmbedLiteSyncServiceImpotUtils()
{
    Cu.import("resource://services-common/log4moz.js");
    Cu.import("resource://services-sync/main.js");
    Cu.import("resource://services-sync/constants.js");
    Cu.import("resource://services-sync/service.js");
    Cu.import("resource://services-sync/policies.js");
    Cu.import("resource://services-sync/util.js");
    Cu.import("resource://services-sync/engines.js");
    Cu.import("resource://services-sync/record.js");
    Cu.import("resource://services-sync/engines/history.js");
    Cu.import("resource://services-sync/engines/apps.js");
    Cu.import("resource://services-sync/engines/forms.js");
    Cu.import("resource://services-sync/engines/passwords.js");
    Cu.import("resource://services-sync/engines/prefs.js");
    Cu.import("resource://services-sync/engines/tabs.js");
    Cu.import("chrome://embedlite/content/sync/bookmarks.js");
}

// Common helper service

function EmbedLiteSyncService()
{
  Logger.debug("JSComp: EmbedLiteSyncService.js loaded");
}


EmbedLiteSyncService.prototype = {
  classID: Components.ID("{36896ad0-9b49-11e2-ae7c-6f7993904c41}"),

  observe: function (aSubject, aTopic, aData) {
    switch(aTopic) {
      // Engine DownloadManager notifications
      case "app-startup": {
        Logger.debug("EmbedLiteSyncService app-startup");
        Services.prefs.setCharPref("services.sync.registerEngines", "Tab,Bookmarks,Form,History,Password,Prefs");
        Services.obs.addObserver(this, "embedui:initsync", true);
        break;
      }
      case "embedui:initsync": {
        Logger.debug("EmbedLiteSyncService embedui:initsync");
        var data = JSON.parse(aData);
        EmbedLiteSyncServiceImpotUtils();
        Service.login(data.username, data.password, data.key);
        //this.embedLiteSyncServiceFetchBookmarks();
        //this.embedLiteSyncServiceFetchHistory();
        //this.embedLiteSyncServiceFetchTabs();
        //this.embedLiteSyncServiceFetchForms();
        //this.embedLiteSyncServiceFetchPassword();
        //this.embedLiteSyncServiceFetchPrefs();
        break;
      }
    }
  },

  _embedLiteSyncServiceFetch: function (collection, Type, callback) {
    let key = Service.collectionKeys.keyForCollection(collection);
    let coll = new Collection(Service.storageURL + collection, Type, Service);
    coll.full = true;
    coll.recordHandler = function(item) {
      item.collection = collection;
      item.decrypt(key);
      callback(item.cleartext);
    };
    coll.get();
  },

  embedLiteSyncServiceFetchBookmarks: function () {
    this._embedLiteSyncServiceFetch("bookmarks", PlacesItem, function(item) {
      if (item.type == "bookmark") {
        Logger.debug("Title:", item.title, "Uri:", item.bmkUri);
      }
    });
  },

  embedLiteSyncServiceFetchHistory: function () {
    this._embedLiteSyncServiceFetch("history", HistoryRec, function(item) {
      Logger.debug("Title:", item.title, "Uri:", item.histUri);
    });
  },

  embedLiteSyncServiceFetchTabs: function () {
    this._embedLiteSyncServiceFetch("tabs", TabSetRecord, function(item) {
      Logger.debug("Tab:", JSON.stringify(item));
    });
  },
  embedLiteSyncServiceFetchForms: function () {
    this._embedLiteSyncServiceFetch("forms", FormRec, function(item) {
      Logger.debug("Forms:", JSON.stringify(item));
    });
  },
  embedLiteSyncServiceFetchPassword: function () {
    this._embedLiteSyncServiceFetch("passwords", LoginRec, function(item) {
      Logger.debug("Login:", JSON.stringify(item));
    });
  },
  embedLiteSyncServiceFetchPrefs: function () {
    this._embedLiteSyncServiceFetch("prefs", PrefRec, function(item) {
      Logger.debug("Pref:", JSON.stringify(item));
    });
  },

  QueryInterface: XPCOMUtils.generateQI([Ci.nsIObserver, Ci.nsISupportsWeakReference])
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([EmbedLiteSyncService]);
