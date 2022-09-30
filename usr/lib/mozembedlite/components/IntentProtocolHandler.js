/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
 * IntentProtocolHandler.js
 */

"use strict";

const {classes: Cc, interfaces: Ci, results: Cr} = Components;

const { XPCOMUtils } = ChromeUtils.import('resource://gre/modules/XPCOMUtils.jsm');

function IntentProtocolHandler() {
}

IntentProtocolHandler.prototype = {

  scheme: "intent",
  protocolFlags: Ci.nsIProtocolHandler.URI_LOADABLE_BY_ANYONE,

  newURI: function(aSpec, aOriginCharset, aBaseURI) {
    let ioService = Cc["@mozilla.org/network/io-service;1"].getService(Ci.nsIIOService);
    // Just replace intent scheme with https to fix Android google maps links
    let uri = ioService.newURI(aSpec.replace('intent:', 'https:'), null, null);
    return uri;
  },

  classID: Components.ID("{878c8294-b764-48fd-87be-7d5e7a44faa9}"),
  QueryInterface: ChromeUtils.generateQI([Ci.nsIProtocolHandler])
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([IntentProtocolHandler]);
