/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2020 Open Mobile Platform LLC.
 */

let Logger = {
  enabled: false,
  getenv: function (name) {
    try {
      var environment = Components.classes["@mozilla.org/process/environment;1"].
                                getService(Components.interfaces.nsIEnvironment);
      return environment.get(name);
    } catch(e) {
      this.debug("Logger.js getEnvironment:", e);
    }
  },

  init: function doInit() {
    this.enabled = this.getenv("EMBEDLITE_COMPONENTS_LOGGING") == 1 || false;
  },

  /*
     * Console printing utilities
     */

  dumpf: function dumpf(str) {
    let args = arguments;
    let i = 1;
    dump(str.replace(/%s/g, function() {
      if (i >= args.length) {
        throw "dumps received too many placeholders and not enough arguments";
      }
      return args[i++].toString();
    }));
  },

  debug: function() {
    if (!this.enabled)
      return;

    var args = Array.prototype.slice.call(arguments);
    dump(args.join(" ") + "\n");
  },

  warn: function() {
    var args = Array.prototype.slice.call(arguments);
    dump(args.join(" ") + "\n");
  }
}

Logger.init();
