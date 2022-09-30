/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cr = Components.results;

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");
const { LoginManagerParent } = ChromeUtils.import("resource://gre/modules/LoginManagerParent.jsm");
const { L10nRegistry, FileSource } = ChromeUtils.import("resource://gre/modules/L10nRegistry.jsm");

// Touch the recipeParentPromise lazy getter so we don't get
// `this._recipeManager is undefined` errors during tests.
// Inspered by browser/components/extensions/test/browser/head.js
void LoginManagerParent.recipeParentPromise;

ChromeUtils.defineModuleGetter(
  this,
  "ActorManagerParent",
  "resource://gre/modules/ActorManagerParent.jsm"
);

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

// Common helper service

function EmbedLiteGlobalHelper()
{
  ActorManagerParent.flush();

  L10nRegistry.registerSource(new FileSource(
                                  "0-mozembedlite",
                                  ["en-US", "fi", "ru"],
                                  "chrome://browser/content/localization/{locale}/"))

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

        Services.ppmm.loadProcessScript(
          "chrome://global/content/process-content.js",
          true
        );
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
          // Bug 1531959 - Change all RemoteLogins message names to PasswordManager in pwmgr code
          // https://github.com/sailfishos-mirror/gecko-dev/commit/1371a0545cdd9323b5a6fea14ad3a78658c9bace)
          // Bug 1527828 - Remove insecure password field detection code for the address bar
          // https://github.com/sailfishos-mirror/gecko-dev/commit/87888ef23587b953bd3045f745d74ab6c9d010eb
          // Bug 1567175, support password manager in out of process iframes
          // https://github.com/sailfishos-mirror/gecko-dev/commit/7410901165d99b03feb66a67d2fe7a114e251f0f

          var globalMM = Services.mm;

          // TODO: Check / verify tht login manager works as it should (JB#55397 / JOLLA-337).
          // Bug 1567175, support password manager in out of process iframes
          // https://github.com/sailfishos-mirror/gecko-dev/commit/7410901165d99b03feb66a67d2fe7a114e251f0f

          globalMM.addMessageListener("PasswordManager:findLogins", LoginManagerParent);
          globalMM.addMessageListener("PasswordManager:findRecipes", LoginManagerParent);
          globalMM.addMessageListener("PasswordManager:onFormSubmit", LoginManagerParent);
          globalMM.addMessageListener("PasswordManager:autoCompleteLogins", LoginManagerParent);
          globalMM.addMessageListener("PasswordManager:removeLogin", LoginManagerParent);
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

  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver, Ci.nsISupportsWeakReference, Ci.nsIFormSubmitObserver])
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([EmbedLiteGlobalHelper]);
