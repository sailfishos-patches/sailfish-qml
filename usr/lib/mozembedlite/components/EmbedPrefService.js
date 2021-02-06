/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cr = Components.results;

Components.utils.import("resource://gre/modules/XPCOMUtils.jsm");
Components.utils.import("resource://gre/modules/Services.jsm");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

// -----------------------------------------------------------------------
// Interface for requesting information on prefs values ​​and setting them
// -----------------------------------------------------------------------

function EmbedPrefService()
{
  Logger.debug("JSComp: EmbedPrefService.js loaded");
}

EmbedPrefService.prototype = {
  classID: Components.ID("{4c5563a0-94eb-11e2-a5f4-7f3c5758e2ae}"),

  _getPrefs: function AC_getPrefs() {
    let list = Services.prefs.getChildList("", {}).filter(function(element) {
      // Avoid displaying "private" preferences
      return !(/^capability\./.test(element));
    });

    let prefs = list.sort().map(this._getPref, this);
    return prefs;
  },

  _getPref: function AC_getPref(aPrefName) {
    let pref = {
      name: aPrefName,
      value:  "",
      modified: Services.prefs.prefHasUserValue(aPrefName),
      lock: Services.prefs.prefIsLocked(aPrefName),
      type: Services.prefs.getPrefType(aPrefName)
    };

    try {
      switch (pref.type) {
        case Ci.nsIPrefBranch.PREF_BOOL:
          pref.value = Services.prefs.getBoolPref(aPrefName).toString();
          break;
        case Ci.nsIPrefBranch.PREF_INT:
          pref.value = Services.prefs.getIntPref(aPrefName).toString();
          break;
        default:
        case Ci.nsIPrefBranch.PREF_STRING:
          pref.value = Services.prefs.getStringPref(aPrefName);
          break;
      }
    } catch (e) {}

    return pref;
  },

  observe: function (aSubject, aTopic, aData) {
    switch(aTopic) {
      // Engine DownloadManager notifications
      case "app-startup": {
        Logger.debug("EmbedPrefService app-startup");
        Services.obs.addObserver(this, "embedui:prefs", true);
        Services.obs.addObserver(this, "embedui:saveprefs", true);
        Services.obs.addObserver(this, "embedui:allprefs", true);
        Services.obs.addObserver(this, "embedui:setprefs", true);
        Services.obs.addObserver(this, "embedui:clearprefs", true);
        Services.obs.addObserver(this, "embed:addPrefChangedObserver", true);
        Services.obs.addObserver(this, "embed:removePrefChangedObserver", true);
        break;
      }
      case "embedui:prefs": {
        var data = JSON.parse(aData);
        Logger.debug("UI Wants some prefs back:", data.msg);
        let retPrefs = [];
        for (let pref of data.prefs) {
            Logger.debug("pref:", pref);
            switch (Services.prefs.getPrefType(pref)) {
                case Services.prefs.PREF_BOOL:
                    retPrefs.push({ name: pref, value: Services.prefs.getBoolPref(pref)});
                    break;
                case Services.prefs.PREF_INT:
                    retPrefs.push({ name: pref, value: Services.prefs.getIntPref(pref)});
                    break;
                case Services.prefs.PREF_STRING:
                    retPrefs.push({ name: pref, value: Services.prefs.getStringPref(pref)});
                    break;
                case Services.prefs.PREF_INVALID:
                    continue;
            }
        }
        Services.obs.notifyObservers(null, "embed:prefs", JSON.stringify(retPrefs));
        break;
      }
      case "embedui:saveprefs": {
        Services.prefs.savePrefFile(null);
        break;
      }
      case "embedui:allprefs": {
        let prefs = this._getPrefs()
        Services.obs.notifyObservers(null, "embed:allprefs", JSON.stringify(prefs));
        break;
      }
      case "embedui:clearprefs": {
        let prefs = JSON.parse(aData).prefs;
        for (var i in prefs) {
          Services.prefs.clearUserPref(prefs[i]);
        }
        break;
      }
      case "embed:addPrefChangedObserver": {
        let pref = JSON.parse(aData);
        Services.prefs.addObserver(pref.name, this, true);
        Services.obs.notifyObservers(null, "embed:nsPrefChanged", JSON.stringify(this._getPref(pref.name)));
        break;
      }
      case "embed:removePrefChangedObserver": {
        let pref = JSON.parse(aData);
        Services.prefs.removeObserver(pref.name, this);
        break;
      }
      case "nsPref:changed": {
        Services.obs.notifyObservers(null, "embed:nsPrefChanged", JSON.stringify(this._getPref(aData)));
        break;
      }
      case "embedui:setprefs": {
        let prefs = JSON.parse(aData).prefs;
        for (var i in prefs) {
          switch (typeof(prefs[i].value)) {
            case "string":
            Services.prefs.setStringPref(prefs[i].name, prefs[i].value);
            break;
          case "number":
            Services.prefs.setIntPref(prefs[i].name, prefs[i].value);
            break;
          case "boolean":
            Services.prefs.setBoolPref(prefs[i].name, prefs[i].value);
            break;
          default:
            throw new Error("Unexpected value type: " + typeof(prefs[i].value));
          }
        }
        break;
      }
    }
  },

  QueryInterface: XPCOMUtils.generateQI([Ci.nsIObserver, Ci.nsISupportsWeakReference])
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([EmbedPrefService]);
