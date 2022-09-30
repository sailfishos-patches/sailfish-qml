/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
const Cc = Components.classes;
const Ci = Components.interfaces;

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

let modules = {
  // about:
  "": {
    uri: "chrome://browser/content/about.xhtml",
    privileged: true
  },

  certerror: {
    uri: "chrome://browser/content/aboutCertError.xhtml",
    privileged: false,
    hide: true
  },

  home: {
    uri: "about:mozilla",
    privileged: false
  },

  // about:fennec and about:firefox are aliases for about:,
  // but hidden from about:about
  embedlite: {
    uri: "https://wiki.mozilla.org/Embedding/IPCLiteAPI",
    privileged: false,
    hide: false
  }
}

function AboutRedirector() {
  Logger.debug("JSComp: AboutRedirector.js loaded");
}
AboutRedirector.prototype = {
  QueryInterface: ChromeUtils.generateQI([Ci.nsIAboutModule]),
  classID: Components.ID("{59f3da9a-6c88-11e2-b875-33d1bd379849}"),

  _getModuleInfo: function (aURI) {
    let moduleName = aURI.pathQueryRef.replace(/[?#].*/, "").toLowerCase();
    return modules[moduleName];
  },

  // nsIAboutModule
  getURIFlags: function(aURI) {
    let flags;
    let moduleInfo = this._getModuleInfo(aURI);
    if (moduleInfo.hide)
      flags = Ci.nsIAboutModule.HIDE_FROM_ABOUTABOUT;

    return flags | Ci.nsIAboutModule.ALLOW_SCRIPT;
  },

  newChannel: function(aURI, aLoadInfo) {
    let moduleInfo = this._getModuleInfo(aURI);

    let pageURI = Services.io.newURI(moduleInfo.uri);
    var channel = Services.io.newChannelFromURIWithLoadInfo(pageURI, aLoadInfo);

    if (!moduleInfo.privileged) {
      // Setting the owner to null means that we'll go through the normal
      // path in GetChannelPrincipal and create a codebase principal based
      // on the channel's originalURI
      channel.owner = null;
    }

    channel.originalURI = aURI;

    return channel;
  }
};

const components = [AboutRedirector];
this.NSGetFactory = XPCOMUtils.generateNSGetFactory(components);
