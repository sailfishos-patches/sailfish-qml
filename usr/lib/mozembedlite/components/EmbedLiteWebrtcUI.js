/* -*- indent-tabs-mode: nil; js-indent-level: 2 -*- */
/* vim: set ts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2021 Open Mobile Platform LLC.
 */

"use strict";

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cu = Components.utils;

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");

XPCOMUtils.defineLazyModuleGetter(this, "Services",
                                  "resource://gre/modules/Services.jsm");
XPCOMUtils.defineLazyServiceGetter(this, "MediaManagerService",
                                   "@mozilla.org/mediaManagerService;1",
                                   "nsIMediaManagerService");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

function debug(...args)
{
  Logger.debug("JSComp: EmbedLiteWebrtcUI.js:", args);
}

function WebrtcPermissionRequest(uri, principal, devices, constraints, callID) {
  this.uri = uri;
  this.principal = principal;
  this.id = callID
  this.permissions = {}
  this.allowedDevices = Cc["@mozilla.org/array;1"].createInstance(Ci.nsIMutableArray);

  let audioDevices = []
  let videoDevices = []
  for (let dev of devices) {
    let device = dev.QueryInterface(Ci.nsIMediaDevice);
    debug("Found " + device.type + " device '" + device.name + "'");
    switch (device.type) {
      case "audioinput":
        if (constraints.audio)
          audioDevices.push(device);
        break;
      case "videoinput":
        if (constraints.video)
          videoDevices.push(device);
        break;
    }
  }

  if (audioDevices.length) {
    this.permissions["microphone"] = audioDevices
  }
  if (videoDevices.length) {
    this.permissions["camera"] = videoDevices
  }
}

WebrtcPermissionRequest.prototype = {
  submit: function(winId, resolve, reject) {
    this.resolve = resolve;
    this.reject = reject;

    let permsToAsk = {}
    // Iterate over all requested media types.
    for (var type in this.permissions) {
      let availableDevices = this.permissions[type]
      let selection = this._autoSelectDevice(type, availableDevices);

      if (selection == undefined) {
        // The permission is not handled. Ask user, what to do.
        permsToAsk[type] = availableDevices
      } else if (selection >= 0) {
        // The permission has been handled.
        this.allowedDevices.appendElement(availableDevices[selection])
      } else {
        debug(type + " denied");
      }
    }
    // If nothing to ask.
    if (!Object.keys(permsToAsk).length) {
      debug("Existing permission handled");
      resolve(this.allowedDevices);
      return;
    }

    let request = {
      id: this.id,
      origin: this.uri.host ? this.uri.host : this.uri.filePath,
      // Iterate over devices in the dict and get their names:
      // {devType: [nsIMediaDevice]} -> {devType: [string]}
      devices: Object.keys(permsToAsk).reduce((result, key) => {
          result[key] = permsToAsk[key].map(dev => dev.name);
          return result;
      }, {})
    };

    // Fixup the request.
    //
    // Pulseaudio's policies won't let us choose an arbitrary device,
    // so just show only one available microphone. This may be changed
    // in the future.
    if ("microphone" in request.devices) {
      debug("Microphone list replaced");
      request.devices["microphone"] = ["Integrated microphone"];
    }

    let requestData = JSON.stringify(request);
    debug("Submitting request " + this.id + " " + requestData);

    Services.embedlite.sendAsyncMessage(
      winId,
      "embed:webrtcrequest",
      requestData
    );
  },

  _autoSelectDevice: function(type, availableDevices) {
    // If the permission has already been granted
    let result = Services.perms.testExactPermissionFromPrincipal(this.principal, type);
    if (result == Ci.nsIPermissionManager.ALLOW_ACTION) {
      if (type == "camera") {
        // Add one-shot permission to use camera
        Services.perms.addFromPrincipal(this.principal, "MediaManagerVideo",
                           Ci.nsIPermissionManager.ALLOW_ACTION,
                           Ci.nsIPermissionManager.EXPIRE_SESSION);
      }
      // Use first available device. Assume Gecko has them sorted by importance.
      // Perhaps a better algorithm can be implemented here.
      return 0;
    } else if (result == Ci.nsIPermissionManager.DENY_ACTION) {
      // The use of this type of media devices is denied on this site.
      return -1;
    }
    // Let the user decide.
    return undefined;
  },

  onResponse: function(response) {
    try {
      // Collect the user's choice
      for (var type in response.choices) {
        // Make the permission permanent, if needed
        if (response.checkedDontAsk) {
          const policy = response.allow ? Ci.nsIPermissionManager.ALLOW_ACTION
                                        : Ci.nsIPermissionManager.DENY_ACTION;
          Services.perms.addFromPrincipal(this.principal, type, policy);
        }

        // Append the selected device to the list of allowed
        if (response.allow) {
          let availableDevices = this.permissions[type]
          let selectedIndex = response.choices[type];
          if (selectedIndex >= 0
              && availableDevices
              && availableDevices.length > selectedIndex) {
            this.allowedDevices.appendElement(availableDevices[selectedIndex]);
            // Add one-shot permission to use camera
            if (type == "camera") {
              Services.perms.addFromPrincipal(this.principal, "MediaManagerVideo",
                                 Ci.nsIPermissionManager.ALLOW_ACTION,
                                 Ci.nsIPermissionManager.EXPIRE_SESSION);
            }
          }
        }
      }
      // Existing permissions will be granted even if the user rejected the dialogue.
      this.resolve(this.allowedDevices);
    }
    catch (e) {
      this.reject(e);
    }
  }
}

function EmbedLiteWebrtcUI()
{
  this._pendingRequests = []
  debug("loaded");
}

EmbedLiteWebrtcUI.prototype = {
  classID: Components.ID("{08b3fb7b-b5c6-4d3c-b9c0-bde7aa0674f7}"),

  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver]),

  _pendingRequests: [],

  onMessageReceived: function(messageName, message) {
    debug("onMessageReceived: top:" + messageName + ", msg:" + message);
    if (messageName === "embedui:webrtcresponse") {
      var ret = JSON.parse(message);
      if (ret.id) {
        let request = this._pendingRequests[ret.id];
        if (request) {
          request.onResponse(ret);
        }
      }
    }
  },

  _idle: function() {
    return Object.keys(this._pendingRequests).length === 0;
  },

  _submitRequest: function(request, winId) {
    return new Promise((resolve, reject) => {
      if (!(request.id in this._pendingRequests)) {
        if (this._idle()) {
          Services.embedlite.addMessageListener("embedui:webrtcresponse", this);
          debug("Subscribed to embedui:webrtcresponse")
        }
        this._pendingRequests[request.id] = request;
        request.submit(winId, resolve, reject);
      }
    });
  },

  _removeRequest: function(request) {
    debug("Deleting request " + request.id);
    delete this._pendingRequests[request.id];
    if (this._idle()) {
      Services.embedlite.removeMessageListener("embedui:webrtcresponse", this);
      debug("Unsubscribed from embedui:webrtcresponse")
    }
  },

  _prompt: function(
    aContentWindow,
    aCallID,
    aConstraints,
    aDevices,
    aSecure)
  {
    if (!aDevices.length) {
      Services.obs.notifyObservers(null, "getUserMedia:response:deny", aCallID);
      return;
    }

    let uri = aContentWindow.document.documentURIObject;
    let principal = Services.scriptSecurityManager.createContentPrincipal(uri, {});
    let winId = Services.embedlite.getIDByWindow(aContentWindow);

    let request = new WebrtcPermissionRequest(uri, principal, aDevices, aConstraints, aCallID);
    this._submitRequest(request, winId)
      .then(allowedDevices => {
        if (allowedDevices && allowedDevices.length) {
          debug("getUserMedia:response:allow for callID " + aCallID);
          Services.obs.notifyObservers(allowedDevices, "getUserMedia:response:allow", aCallID);
        } else {
          debug("getUserMedia:response:deny for callID " + aCallID);
          Services.obs.notifyObservers(null, "getUserMedia:response:deny", aCallID);
        }
      })
      .catch(e => {
        debug("An exception occured: " + e);
        Services.obs.notifyObservers(null, "getUserMedia:response:deny", aCallID);
        Cu.reportError(e);
      })
      .finally(() => {
        this._removeRequest(request);
      });
  },

  observe: function(aSubject, aTopic, aData) {
    debug("got " + aTopic)
    switch (aTopic) {
      case "app-startup":
        Services.obs.addObserver(this, "getUserMedia:ask-device-permission", false);
        Services.obs.addObserver(this, "getUserMedia:request", false);
        Services.obs.addObserver(this, "PeerConnection:request", false);
        Services.obs.addObserver(this, "recording-device-events", false);
        break;

      case "getUserMedia:ask-device-permission":
        // No need to ask permission to enumerate devices (yet?).
        Services.obs.notifyObservers(aSubject, "getUserMedia:got-device-permission");
        break;

      case "PeerConnection:request":
        Services.obs.notifyObservers(null, "PeerConnection:response:allow", aSubject.callID);
        break;

      case "getUserMedia:request":
        let constraints = aSubject.getConstraints();
        let contentWindow = Services.wm.getOuterWindowWithId(aSubject.windowID);

        contentWindow.navigator.mozGetUserMediaDevices(
          constraints,
          function(devices) {
            if (!contentWindow.closed) {
              EmbedLiteWebrtcUI.prototype._prompt(
                contentWindow,
                aSubject.callID,
                constraints,
                devices,
                aSubject.isSecure);
            }
          },
          function(error) {
            Services.obs.notifyObservers(null, "getUserMedia:request:deny", aSubject.callID);
            Cu.reportError(error);
          },
          aSubject.innerWindowID,
          aSubject.callID
        );
        break;

      case "recording-device-events":
        let windows = MediaManagerService.activeMediaCaptureWindows;
        let webrtcMediaInfo = { "video": false, "audio": false};

        for (let i = 0; i < windows.length; i++) {
          let win = windows.queryElementAt(i, Ci.nsIDOMWindow);
          let hasCamera = {};
          let hasMicrophone = {};
          let screenShare = {};
          let windowShare = {};
          let browserShare = {};
          let mediaDevices = {};

          MediaManagerService.mediaCaptureWindowState(
            win,
            hasCamera,
            hasMicrophone,
            screenShare,
            windowShare,
            browserShare,
            mediaDevices,
            true /* aIncludeDescendants */);
          if (hasCamera.value != MediaManagerService.STATE_NOCAPTURE)
            webrtcMediaInfo.video = true;
          if (hasMicrophone.value != MediaManagerService.STATE_NOCAPTURE)
            webrtcMediaInfo.audio = true;
        }

        let info = JSON.stringify(webrtcMediaInfo)
        debug("devices in use: " + info);
        Services.obs.notifyObservers(null, "webrtc-media-info", info);
    }
  }
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([EmbedLiteWebrtcUI]);
