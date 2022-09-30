/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Copyright (c) 2020 Open Mobile Platform LLC. */

const Cc = Components.classes;
const Ci = Components.interfaces;

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");

XPCOMUtils.defineLazyServiceGetter(Services, "embedlite",
                                    "@mozilla.org/embedlite-app-service;1",
                                    "nsIEmbedAppService");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

function ContentPermissionManager() {
  Logger.debug("JSComp: ContentPermissionManager.js loaded");
}

function debug(msg) {
  Logger.debug("PermissionManager:", msg);
}

function sendResult(topic, result) {
  Services.obs.notifyObservers(null, topic, JSON.stringify(result));
}

ContentPermissionManager.prototype = {
  classID: Components.ID("{86d354c6-81bc-4eb5-82c3-4c9859586165}"),

  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver]),

  observe: function(aSubject, aTopic, aData) {
      switch (aTopic) {
      case "app-startup":
          Services.obs.addObserver(this, "embedui:perms", false);
          break;
      case "embedui:perms":
          var data = JSON.parse(aData);

          switch (data.msg) {
          case "get-all":
              let permissionList = [];
              Services.perms.all.forEach(permission => {
                  permissionList.push({
                                  type: permission.type,
                                  uri: permission.principal.origin,
                                  capability: permission.capability,
                                  expireType: permission.expireType
                              })
              });
              sendResult("embed:perms:all", permissionList);
              break;
          case "get-all-for-uri":
              let result = [];
              let permissions = Services.perms.getAllForPrincipal(Services.scriptSecurityManager.createContentPrincipal(Services.io.newURI(data.uri, null, null), {}));
              for (let permission of permissions) {
                  result.push({
                                  type: permission.type,
                                  uri: data.uri,
                                  capability: permission.capability,
                                  expireType: permission.expireType
                              });
              }
              sendResult("embed:perms:all-for-uri", result);
              break;
          case "add":
              Services.perms.addFromPrincipal(Services.scriptSecurityManager.createContentPrincipal(Services.io.newURI(data.uri, null, null), {}),
                                              data.type,
                                              parseInt(data.permission),
                                              parseInt(data.expireType));
              debug("set, uri: " + data.uri
                    + ", type: " + data.type
                    + ", permission: " + data.permission);
              break;
          case "remove":
              Services.perms.removeFromPrincipal(Services.scriptSecurityManager.createContentPrincipal(Services.io.newURI(data.uri, null, null), {}),
                                                 data.type);
              debug("remove type: " + data.type + ", for uri: " + data.uri);
              break;
          case "remove-all":
              Services.perms.removeAll();
              debug("remove all permissions");
              break;
          }
          break;
      }
  }
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([ContentPermissionManager]);
