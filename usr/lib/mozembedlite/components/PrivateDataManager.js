/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const Cc = Components.classes;
const Ci = Components.interfaces;

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

function debug(aMsg) {
  Logger.debug("PrivateDataManager.js:", aMsg);
}

function PrivateDataManager() {
  Logger.debug("JSComp: PrivateDataManager.js loaded");
}

function sendResult(topic, result) {
  Services.obs.notifyObservers(null, topic, JSON.stringify(result));
}

PrivateDataManager.prototype = {
  classID: Components.ID("{6a7dd2ef-b7c8-4ab5-8c35-c0e5d7557ccf}"),
  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver, Ci.nsISupportsWeakReference]),

  get loginManager() {
    return Cc["@mozilla.org/login-manager;1"].getService(Ci.nsILoginManager);
  },

  clearData: function(dataType) {
    (async () => {
      await new Promise(function(resolve) {
        Services.clearData.deleteData(dataType, resolve);
        debug("Data cleared", dataType)
      });
    })().catch(Cu.reportError);
  },

  _cacheSizeObserver: null,

  _cacheSizePromise: null,

  _siteDataSizePromise: null,

  get cacheSizePromise () {
    if (this._cacheSizePromise) {
      return this._cacheSizePromise;
    }

    this._cacheSizePromise = new Promise((resolve, reject) => {
      // Needs to root the observer since cache service keeps only a weak reference.
      this._cacheSizeObserver = {
        onNetworkCacheDiskConsumption: consumption => {
          resolve(consumption);
          this._cacheSizePromise = null;
          this._cacheSizeObserver = null;
        },

        QueryInterface: ChromeUtils.generateQI([
          Ci.nsICacheStorageConsumptionObserver,
          Ci.nsISupportsWeakReference
        ])
      };

      try {
        Services.cache2.asyncGetDiskConsumption(this._cacheSizeObserver);
      } catch (e) {
        reject(e);
        this._cacheSizePromise = null;
        this._cacheSizeObserver = null;
      }
    });

    return this._cacheSizePromise;
  },

  get siteDataSizePromise() {
    if (this._siteDataSizePromise) {
      return this._siteDataSizePromise;
    }
    this._siteDataSizePromise = new Promise((resolve, reject) => {
      try {
        Services.qms.getUsage(function (request) {
          let usage = 0;
          if (request.resultCode == Cr.NS_OK) {
            let items = request.result;
            for (let item of items) {
              usage += item.usage;
            }
          }
          resolve(usage);
          this._siteDataSizePromise = null;
        });
      } catch (e) {
        debug("error in calculating site data size: " + e);
        reject(e);
        this._siteDataSizePromise = null;
      }
    });
    return this._siteDataSizePromise;
  },

  clearPrivateData: function (aData) {
    switch (aData) {
      case "passwords": {
        this.loginManager.removeAllLogins();
        debug("Passwords removed");
        break;
      }
      case "cookies-and-site-data": {
        this.clearData(Ci.nsIClearDataService.CLEAR_COOKIES | Ci.nsIClearDataService.CLEAR_DOM_STORAGES);
        break;
      }
      case "cache": {
        this.clearData(Ci.nsIClearDataService.CLEAR_ALL_CACHES);
        break;
      }
    }
  },

  observe: function (aSubject, aTopic, aData) {
    switch (aTopic) {
      case "app-startup": {
        Services.obs.addObserver(this, "clear-private-data", true);
        Services.obs.addObserver(this, "get-cache-size", true);
        Services.obs.addObserver(this, "get-site-data-size", true);
        break;
      }
      case "clear-private-data": {
        this.clearPrivateData(aData);
        break;
      }
      case "get-cache-size": {
        this.cacheSizePromise.then(usage => {
          sendResult("cache-size", { "usage": usage });
        }, Cu.reportError);
        break;
      }
      case "get-site-data-size": {
        this.siteDataSizePromise.then(usage => {
          sendResult("site-data-size", { "usage": usage });
        }, Cu.reportError);
        break;
      }
    }
  }
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([PrivateDataManager]);
