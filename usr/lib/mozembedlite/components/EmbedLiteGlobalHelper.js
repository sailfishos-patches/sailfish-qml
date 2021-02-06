/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cr = Components.results;

Components.utils.import("resource://gre/modules/XPCOMUtils.jsm");
Components.utils.import("resource://gre/modules/Services.jsm");
Components.utils.import("resource://gre/modules/LoginManagerParent.jsm");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

// Common helper service

function EmbedLiteGlobalHelper()
{
  Logger.debug("JSComp: EmbedLiteGlobalHelper.js loaded");
}

EmbedLiteGlobalHelper.prototype = {
  classID: Components.ID("{6322b72e-9764-11e2-8566-cbaca05819ea}"),

  observe: function (aSubject, aTopic, aData) {
    switch(aTopic) {
      // Engine DownloadManager notifications
      case "app-startup": {
        Logger.debug("EmbedLiteGlobalHelper app-startup");
        Services.obs.addObserver(this, "invalidformsubmit", false);
        Services.obs.addObserver(this, "xpcom-shutdown", false);
        Services.obs.addObserver(this, "profile-after-change", false);
        break;
      }
      case "invalidformsubmit": {
        Logger.debug("EmbedLiteGlobalHelper invalidformsubmit");
        break;
      }
      case "profile-after-change": {
        // Init LoginManager
        try {
          Cc["@mozilla.org/login-manager;1"].getService(Ci.nsILoginManager);
          var globalMM = Cc["@mozilla.org/globalmessagemanager;1"].getService(Ci.nsIMessageListenerManager);

          // PLEASE KEEP THIS LIST IN SYNC WITH THE MOBILE LIST IN BrowserCLH.js AND WITH THE DESKTOP LIST IN nsBrowserGlue.js
          // https://git.sailfishos.org/mer-core/gecko-dev/blob/f2e8f311/browser/components/nsBrowserGlue.js#L219
          // https://git.sailfishos.org/mer-core/gecko-dev/blob/f2e8f311/mobile/android/components/BrowserCLH.js#L86
          // SHA1: f2e8f3117a814098cef28ef1000139b836d33a08
          globalMM.addMessageListener("RemoteLogins:findLogins", LoginManagerParent);
          globalMM.addMessageListener("RemoteLogins:findRecipes", LoginManagerParent);
          globalMM.addMessageListener("RemoteLogins:onFormSubmit", LoginManagerParent);
          globalMM.addMessageListener("RemoteLogins:autoCompleteLogins", LoginManagerParent);
          globalMM.addMessageListener("RemoteLogins:removeLogin", LoginManagerParent);
          globalMM.addMessageListener("RemoteLogins:insecureLoginFormPresent", LoginManagerParent);
          // PLEASE KEEP THIS LIST IN SYNC WITH THE MOBILE LIST IN BrowserCLH.js AND WITH THE DESKTOP LIST IN nsBrowserGlue.js

        } catch (e) {
          Logger.warn("E login manager:", e);
        }
        break;
      }
      case "xpcom-shutdown": {
        Logger.debug("EmbedLiteGlobalHelper xpcom-shutdown");
        Services.obs.removeObserver(this, "invalidformsubmit", false);
        Services.obs.removeObserver(this, "xpcom-shutdown", false);
        break;
      }
    }
  },

  notifyInvalidSubmit: function notifyInvalidSubmit(aFormElement, aInvalidElements) {
    Logger.warn("NOT IMPLEMENTED Invalid Form Submit, need to do something about it.");
    if (!aInvalidElements.length)
      return;
  },

  QueryInterface: XPCOMUtils.generateQI([Ci.nsIObserver, Ci.nsISupportsWeakReference, Ci.nsIFormSubmitObserver])
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([EmbedLiteGlobalHelper]);
