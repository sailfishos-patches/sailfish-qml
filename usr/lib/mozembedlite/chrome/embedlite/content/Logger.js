/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2020 Open Mobile Platform LLC.
 */

Components.utils.import("resource://gre/modules/Services.jsm");

let Logger = {
  _enabled: false,
  _consoleEnv: null,

  init: function doInit() {
    try {
      this._consoleEnv = Services.env.get("EMBED_CONSOLE");
    } catch (e) {}

    let consolePref = false;
    try {
      consolePref = Services.prefs.getIntPref("embedlite.console_log.enabled");
    } catch (e) { /*pref is missing*/ }

    this._enabled = this._consoleEnv || consolePref || false;
  },

  get stackTraceEnabled() {
    return this._consoleEnv.indexOf("stacktrace") !== -1;
  },

  get devModeNetworkEnabled() {
    return this._consoleEnv.indexOf("network") !== -1;
  },

  get enabled() {
    return this._enabled;
  },

  /*
   * Logger printing utilities
   */
  debug: function() {
    if (!this._enabled)
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
