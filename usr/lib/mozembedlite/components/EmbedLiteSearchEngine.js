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

// Common helper service
function EmbedLiteSearchEngine()
{
  Logger.debug("JSComp: EmbedLiteSearchEngine.js loaded");
}

EmbedLiteSearchEngine.prototype = {
  classID: Components.ID("{924fe7ba-afa1-11e2-9d4f-533572064b73}"),

  observe: function (aSubject, aTopic, aData) {
    let searchCallback = {
      onSuccess: function (engine) {
        var message = {
          "msg": "search-engine-added",
          "engine": (engine && engine.name) || "",
          "errorCode": 0,
        }
        Services.obs.notifyObservers(null, "embed:search", JSON.stringify(message));
      },
      onError: function (errorCode) {
        // Checked possible failures from nsIBrowserSearchService.idl
        var message = {
          "msg": "search-engine-added",
          "engine": "",
          "errorCode": errorCode
        }
        Services.obs.notifyObservers(null, "embed:search", JSON.stringify(message));
      }
    }

    switch(aTopic) {
      // Engine DownloadManager notifications
      case "app-startup": {
        Services.obs.addObserver(this, "xpcom-shutdown", true);
        Services.obs.addObserver(this, "embedui:search", true);
        Services.obs.addObserver(this, "profile-after-change", false);
        break;
      }
      case "profile-after-change": {
        Services.obs.removeObserver(this, "profile-after-change");
        Services.search.init(function addEngine_cb(rv) {
            let engines = Services.search.getEngines({});
            let engineNames = engines.map(function (element) {
              return element.name;
            });

            let enginesAvailable = (engines && engines.length > 0);
            var messg = {
              msg: "init",
              engines: engineNames,
              defaultEngine: enginesAvailable && Services.search.defaultEngine ?
                Services.search.defaultEngine.name : null
            }
            Services.obs.notifyObservers(null, "embed:search", JSON.stringify(messg));
        });
        break;
      }
      case "embedui:search": {
        var data = JSON.parse(aData);
        switch (data.msg) {
          case "loadxml": {
            Services.search.addEngine(data.uri, Ci.nsISearchEngine.DATA_XML, null, data.confirm, searchCallback);
            break;
          }
          case "restoreDefault": {
            Services.search.restoreDefaultEngines();
            break;
          }
          case "loadtext": {
            Services.search.addEngine(data.uri, Ci.nsISearchEngine.DATA_TEXT, null, data.confirm);
            break;
          }
          case "remove": {
            var engine = Services.search.getEngineByName(data.name);
            if (engine) {
              Services.search.removeEngine(engine);
            }
            break;
          }
          case "setcurrent": {
            var engine = Services.search.getEngineByName(data.name);
            if (engine) {
              Services.search.currentEngine = engine;
            }
            break;
          }
          case "setdefault": {
            var engine = Services.search.getEngineByName(data.name);
            if (engine) {
              // Update currentEngine as well when default search engine is updated.
              Services.search.defaultEngine = engine;
              Services.search.currentEngine = engine;
            }
            break;
          }
          case "getlist": {
            let engines = Services.search.getEngines({});
            var json = [];
            if (engines) {
              for (var i = 0; i < engines.length; i++) {
                let engine = engines[i];
                let serEn = { name: engine.name,
                              isDefault: Services.search.defaultEngine === engine,
                              isCurrent: Services.search.currentEngine === engine };
                json.push(serEn);
              }
            }
            Services.obs.notifyObservers(null, "embed:search", JSON.stringify({ msg: "pluginslist", list: json}));
            break;
          }
          case "getsuggestions": {
            let submission = Services.search.currentEngine.getSubmission(data.searchinput, "application/x-suggestions+json");
            let httpReq = Cc["@mozilla.org/xmlextras/xmlhttprequest;1"].createInstance(Ci.nsIXMLHttpRequest);
            httpReq.onload = function(e) {
              let response = JSON.parse(this.responseText);

              // according to the standard there must be at least two elements in list
              if (!Array.isArray(response) && response.length < 2) {
                return;
              }

              let suggestions = {
                "msg": "suggestions",
                "query": response[0],
                "completions": response[1],
                "descriptions": response[2] ? response[2] : [],
                "urls": response[3] ? response[3] : []
              };

              Services.obs.notifyObservers(null, "embed:search", JSON.stringify(suggestions));

            };
            httpReq.open("get", submission.uri.spec, true);
            httpReq.send();
            break;
          }
        }
        break;
      }
      case "xpcom-shutdown": {
        Services.obs.removeObserver(this, "embedui:search");
        Services.obs.removeObserver(this, "xpcom-shutdown");
        break;
      }
      default:
        break;
    }
  },

  QueryInterface: XPCOMUtils.generateQI([Ci.nsIObserver, Ci.nsISupportsWeakReference])
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([EmbedLiteSearchEngine]);
