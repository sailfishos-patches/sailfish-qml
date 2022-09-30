/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cr = Components.results;

const APP_STARTUP               = "app-startup"
const VIEW_CREATED              = "embedliteviewcreated";
const VIEW_DESTROYED            = "embedliteviewdestroyed";
const VIEW_DESKTOP_MODE_CHANGED = "embedliteviewdesktopmodechanged";
const VIEW_UA_CHANGED           = "embedliteviewhttpuseragentchanged";
const XPCOM_SHUTDOWN            = "xpcom-shutdown";
const PREF_OVERRIDE             = "general.useragent.override";

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");
const { UserAgentOverrides } = ChromeUtils.import("chrome://embedlite/content/UserAgentOverrides.jsm");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

// UserAgentOverrideHelper service
function UserAgentOverrideHelper()
{
  Logger.debug("JSComp: UserAgentOverrideHelper.js loaded");
}

UserAgentOverrideHelper.prototype = {
  classID: Components.ID("{69d68654-b5a0-11e2-bb91-2b8ad5eb98ac}"),

  observe: function (aSubject, aTopic, aData) {
    switch(aTopic) {
      // Engine DownloadManager notifications
      case APP_STARTUP: {
        Logger.debug("UserAgentOverrideHelper app-startup");
        Services.obs.addObserver(this, VIEW_CREATED, true);
        Services.obs.addObserver(this, VIEW_DESKTOP_MODE_CHANGED, true);
        Services.obs.addObserver(this, VIEW_DESTROYED, true);
        Services.obs.addObserver(this, VIEW_UA_CHANGED, true);
        Services.obs.addObserver(this, XPCOM_SHUTDOWN, false);
        UserAgent.init();
        break;
      }
      case VIEW_CREATED: {
        UserAgent.addTabForWindow(aSubject)
        break;
      }
      case VIEW_DESTROYED: {
        UserAgent.removeTabForWindow(aSubject)
        break;
      }
      case VIEW_DESKTOP_MODE_CHANGED: {
        let tab = UserAgent.getTabForWindow(aSubject);
        if (tab) {
          tab.desktopMode = (aData === "true");
        }
        break;
      }
      case VIEW_UA_CHANGED: {
        UserAgent.setUserAgentOverride(aSubject, aData);
        break;
      }
      case XPCOM_SHUTDOWN: {
        Logger.debug("UserAgentOverrideHelper", XPCOM_SHUTDOWN);
        Services.obs.removeObserver(this, XPCOM_SHUTDOWN, false);
        UserAgent.uninit();
        break;
      }
      default:
        break;
    }
  },

  QueryInterface: ChromeUtils.generateQI([Ci.nsISiteSpecificUserAgent, Ci.nsIObserver,
                                         Ci.nsISupportsWeakReference, Ci.nsIFormSubmitObserver])
};

var UserAgent = {
  _debug: false,
  _customUA: null,
  _tabs: [],
  overrideMap: new Map,
  initilized: false,
  userAgent: "",
  DESKTOP_UA: null,
  GOOGLE_DOMAIN: /(^|\.)google\.com$/,
  GOOGLE_MAPS_DOMAIN: /(^|\.)maps\.google\.com$/,
  YOUTUBE_DOMAIN: /(^|\.)youtube\.com$/,
  NOKIA_HERE_DOMAIN: /(^|\.)here\.com$/,

  init: function ua_init() {
    if (this.initilized) {
      return
    }

    Services.obs.addObserver(this.onModifyRequest.bind(this),
                             "http-on-modify-request");
    Services.prefs.addObserver(PREF_OVERRIDE, this, false);

    this.userAgent = Cc["@mozilla.org/network/protocol;1?name=http"]
                       .getService(Ci.nsIHttpProtocolHandler).userAgent

    this._customUA = this.getCustomUserAgent();
    UserAgentOverrides.init();
    UserAgentOverrides.addComplexOverride(this.onRequest.bind(this));
    // See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent/Firefox
    // Same as in moz.configure/init.configure to split the MOZILLA_UAVERSION
    let version = Services.appinfo.version.split(".")[0] + ".0";
    this.DESKTOP_UA = "Mozilla/5.0 (X11; Linux x86_64; rv:" + version + ") Gecko/20100101 Firefox/" + version;
    this.initilized = true;
  },

  onModifyRequest(aSubject, aTopic, aData) {
    if (aTopic === "http-on-modify-request") {
      let channel = aSubject.QueryInterface(Ci.nsIHttpChannel);

      let loadInfo = channel.loadInfo;
      if (loadInfo.securityMode === loadInfo.SEC_REQUIRE_CORS_DATA_INHERITS) {
        // User-agent is not safelisted CORS request header so don't add it when in CORS mode. We may need to change this
        // later to use nsILoadInfo securityFlags: https://bugzilla.mozilla.org/show_bug.cgi?id=1189945 (see also
        // dom/fetch/InternalRequest::MapChannelToRequestMode).
        //
        // This approach works for now. Safelisted CORS request headers can be found here
        // https://github.com/sailfishos-mirror/gecko-dev/blob/esr78/dom/fetch/InternalHeaders.cpp#L314.
        // Fetch spec: https://fetch.spec.whatwg.org/#cors-safelisted-request-header
        return;
      }

      // Cover all google domains
      if (!channel.URI.schemeIs("https") && channel.URI.asciiHost.indexOf(".google.") !== -1) {
        channel.upgradeToSecure();
      }
      let ua = this.onRequest(channel, this.getDefaultUserAgent());
      if (ua) {
        channel.setRequestHeader("User-Agent", ua, false);
      }
    }
  },

  setUserAgentOverride: function(aWindow, httpUserAgent) {
    let tab = this.getTabForWindow(aWindow);
    if (tab) {
      tab.httpuseragentstring = httpUserAgent
    }
  },

  getCustomUserAgent: function() {
    if (Services.prefs.prefHasUserValue(PREF_OVERRIDE)) {
      let ua = Services.prefs.getCharPref(PREF_OVERRIDE);
      return ua;
    } else {
      return null;
    }
  },

  getDefaultUserAgent : function ua_getDefaultUserAgent() {
    if (this._customUA) {
      return this._customUA;
    } else if (this.userAgent) {
      return this.userAgent;
    }
    return this.DESKTOP_UA;
  },

  uninit: function ua_uninit() {
    Services.prefs.removeObserver(PREF_OVERRIDE, this);
    UserAgentOverrides.uninit();
  },

  // Complex override calls this first.
  onRequest: function(channel, defaultUA) {
    let ua = "";
    let uri = channel.URI;
    let loadingPrincipalURI = null;
    let channelWindow = this._getWindowForRequest(channel);

    let tab = this.getTabForWindow(channelWindow);
    if (tab) {
      // Send assigned UA if it has been overridden
      if (tab.httpuseragentstring.length) {
        return tab.httpuseragentstring;
      }
      // Send desktop UA if "Request Desktop Site" is enabled.
      if (tab.desktopMode) {
        return this.DESKTOP_UA;
      }
    }

    // Prefer current uri over the loading principal's uri in case both have overrides.
    ua = uri && UserAgentOverrides.getOverrideForURI(uri)

    if (ua) {
      // Requires also Logger to be enabled
      if (this._debug) {
        Logger.debug("Uri:", uri.asciiHost, "UA:", ua)
      }

      return ua
    } else {
      let loadInfo = channel.loadInfo;
      loadingPrincipalURI = loadInfo && loadInfo.loadingPrincipal && loadInfo.loadingPrincipal.URI;
    }

    if (loadingPrincipalURI && loadingPrincipalURI.asciiHost) {
      ua = UserAgentOverrides.getOverrideForURI(loadingPrincipalURI);
      if (this._debug) {
        Logger.debug("Loading principal uri:", loadingPrincipalURI.asciiHost, "Uri:", uri.asciiHost, "UA:", ua);
      }
      // Fall through to default user-agent if there is no override for the loadingPrincipalURI.
      if (ua) {
        return ua;
      }
    }
    return defaultUA;
  },

  getTabForWindow: function getTabForWindow(aWindow) {
    let tabs = this._tabs;
    for (let i = 0; i < tabs.length; i++) {
      if (tabs[i].contentWindow == aWindow) {
        return tabs[i];
      }
    }
    return null;
  },

  addTabForWindow: function addTabForWindow(aWindow) {
    this._tabs.push({
      "contentWindow" : aWindow,
      "desktopMode" : false,
      "httpuseragentstring" : ""
    });
  },

  removeTabForWindow: function removeTabForWindow(aWindow) {
    let tabs = this._tabs;
    for (let i = 0; i < tabs.length; i++) {
      if (tabs[i].contentWindow == aWindow) {
        tabs.splice(i, 1);
        return;
      }
    }
  },

  _getRequestLoadContext: function ua_getRequestLoadContext(aRequest) {
    if (aRequest && aRequest.notificationCallbacks) {
      try {
        return aRequest.notificationCallbacks.getInterface(Ci.nsILoadContext);
      } catch (ex) { }
    }

    if (aRequest && aRequest.loadGroup && aRequest.loadGroup.notificationCallbacks) {
      try {
        return aRequest.loadGroup.notificationCallbacks.getInterface(Ci.nsILoadContext);
      } catch (ex) { }
    }

    return null;
  },

  _getWindowForRequest: function ua_getWindowForRequest(aRequest) {
    let loadContext = this._getRequestLoadContext(aRequest);
    if (loadContext) {
      try {
        return loadContext.associatedWindow;
      } catch (e) {
        // loadContext.associatedWindow can throw when there's no window
      }
    }

    return null;
  },

  observe: function ua_observe(aSubject, aTopic, aData) {
    switch (aTopic) {
      case "nsPref:changed": {
        if (aData == PREF_OVERRIDE) {
          this._customUA = this.getCustomUserAgent();
        }
        break;
      }
    }
  }
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([UserAgentOverrideHelper]);
