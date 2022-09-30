/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2020 Open Mobile Platform LLC.
 */

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cr = Components.results;

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");

XPCOMUtils.defineLazyServiceGetter(Services, 'env',
                                  '@mozilla.org/process/environment;1',
                                  'nsIEnvironment');

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

// Common helper service

function SPConsoleListener() {
  Logger.debug("JSComp: EmbedLiteConsoleListener.js loaded");
}

SPConsoleListener.prototype = {
  observe: function(msg) {
    if (Logger.enabled) {
      Logger.debug("CONSOLE message:");
      Logger.debug(msg);
    } else {
      Services.obs.notifyObservers(null, "embed:logger", JSON.stringify({ multiple: false, log: msg }));
    }
  },

  QueryInterface: ChromeUtils.generateQI([Ci.nsIConsoleListener])
};

// Captures the data received on a channel for debug output
// See https://developer.mozilla.org/en-US/docs/Mozilla/Creating_sandboxed_HTTP_connections
// and http://www.softwareishard.com/blog/firebug/nsitraceablechannel-intercept-http-traffic/
function DocumentContentListener(aHttpChannel) {
    this.originalListener = null;
    this.receivedData = [];
    this.httpChannel = aHttpChannel;
    this.maxDebugPrint = 32 * 1024;
}

DocumentContentListener.prototype = {
  onDataAvailable: function(request, inputStream, offset, count) {
    var binaryInputStream = Cc["@mozilla.org/binaryinputstream;1"].createInstance(Ci["nsIBinaryInputStream"]);
    var storageStream = Cc["@mozilla.org/storagestream;1"].createInstance(Ci["nsIStorageStream"]);
    var binaryOutputStream = Cc["@mozilla.org/binaryoutputstream;1"].createInstance(Ci["nsIBinaryOutputStream"]);

    binaryInputStream.setInputStream(inputStream);
    storageStream.init(8192, count, null);
    binaryOutputStream.setOutputStream(storageStream.getOutputStream(0));

    // Copy received data as they come
    var data = binaryInputStream.readBytes(count);
    this.receivedData.push(data);

    binaryOutputStream.writeBytes(data, count);

    this.originalListener.onDataAvailable(request, storageStream.newInputStream(0), offset, count);
  },

  onStartRequest: function(request, context) {
    this.originalListener.onStartRequest(request, context);
    var visitor = new DebugHeaderVisitor()

    // Output the headers
    Logger.debug("    [ Request headers --------------------------------------- ]");
    this.httpChannel.visitRequestHeaders(visitor);

    Logger.debug("    [ Response headers -------------------------------------- ]");
    this.httpChannel.visitOriginalResponseHeaders(visitor);
  },

  onStopRequest: function(request, context, statusCode) {
    // Get entire response
    var responseSource = this.receivedData.join("").substring(0, this.maxDebugPrint);
    this.originalListener.onStopRequest(request, context, statusCode);

    // Output the content (sometimes)
    Logger.debug("    [ Document content -------------------------------------- ]");
    if (this.httpChannel.contentCharset !== "") {
      Logger.debug(responseSource);
      if (this.httpChannel.decodedBodySize > this.maxDebugPrint) {
        Logger.debug("        Document output truncated by", (this.httpChannel.decodedBodySize - this.maxDebugPrint),"bytes");
      }
    } else {
        Logger.debug("        Document output skipped, content-type non-text or unknown");
    }
    Logger.debug("    [ Document content ends --------------------------------- ]");
  },

  QueryInterface: function (aIID) {
    if (aIID.equals(Ci.nsIStreamListener) ||
      aIID.equals(Ci.nsISupports)) {
      return this;
    }
    throw Components.results.NS_NOINTERFACE;
  }
}

// Used to cycle through all the headers
function DebugHeaderVisitor() {
}

DebugHeaderVisitor.prototype.visitHeader = function (aHeader, aValue) {
    Logger.debug("       ", aHeader, ":", aValue);
};

// Sets up the channel for debug output
function LogChannelInfo(aSubject) {
  var httpChannel = aSubject.QueryInterface(Components.interfaces.nsIHttpChannel);
  if (httpChannel) {
    var responseStatus = 0;
    var responseStatusText = "";
    var requestMethod = "unknown";
    try {
      responseStatus = httpChannel.responseStatus;
      responseStatusText = httpChannel.responseStatusText;
      requestMethod = httpChannel.requestMethod;
    } catch (e) {}
    Logger.debug("[ Request details ------------------------------------------- ]");
    Logger.debug("    Request:", requestMethod, "status:", responseStatus, responseStatusText);
    Logger.debug("    URL:", httpChannel.URI.spec);

    // At this point the headers and content-type may not be valid, for example if
    // the document is coming from the cache; they'll become available from the
    // listener's onStartRequest callback. See gecko bug 489317.
    var newListener = new DocumentContentListener(httpChannel);
    aSubject.QueryInterface(Ci.nsITraceableChannel);
    newListener.originalListener = aSubject.setNewListener(newListener);
  }
}

// Prefix the component name with $ to ensure it is initalised
// before all other components in the start-up sequence.
function $EmbedLiteConsoleListener()
{
}

$EmbedLiteConsoleListener.prototype = {
  classID: Components.ID("{6b21b5a8-9816-11e2-86f8-fb54170a814d}"),
  _listener: null,

  formatStackFrame: function(aFrame) {
    let functionName = aFrame.functionName || '<anonymous>';
    return '    at ' + functionName +
           ' (' + aFrame.filename + ':' + aFrame.lineNumber +
           ':' + aFrame.columnNumber + ')';
  },

  observe: function (aSubject, aTopic, aData) {
    switch(aTopic) {
      // Engine DownloadManager notifications
      case "app-startup": {
        var runConsoleEnv = 0;
        if (Logger.stackTraceEnabled)
          Services.obs.addObserver(this, 'console-api-log-event', false);

        if (Logger.enabled) {
          this._listener = new SPConsoleListener();
          Services.console.registerListener(this._listener);
        }
        Services.obs.addObserver(this, "embedui:logger", true);

        if (Logger.devModeNetworkEnabled) {
          Services.obs.addObserver(this, 'http-on-examine-response', false);
        }

        break;
      }
      case "http-on-examine-response": {
        LogChannelInfo(aSubject);
        break;
      }
      case "embedui:logger": {
        var data = JSON.parse(aData);
        if (data.enabled) {
          Services.console.registerListener(this._listener);
        } else {
          Services.console.unregisterListener(this._listener);
        }
        break;
      }
      case "console-api-log-event": {
        this._handleConsoleMessage(aSubject);
        break;
      }
    }
  },

  _handleConsoleMessage(aMessage) {
    // This code has been adapted from
    // gecko-dev/mobile/android/modules/geckoview/GeckoViewConsole.jsm
    // https://github.com/sailfishos-mirror/gecko-dev/blob/2834d64c4b16c7b93857fd58ca55dc76d8176bfd/mobile/android/modules/geckoview/GeckoViewConsole.jsm#L55
    aMessage = aMessage.wrappedJSObject;

    const mappedArguments = Array.from(aMessage.arguments, this.formatResult, this);
    const joinedArguments = mappedArguments.join(" ");
    const functionName = aMessage.functionName || "anonymous";

    if (aMessage.level == "error" || aMessage.level == "warn") {
      const flag = aMessage.level == "error" ? Ci.nsIScriptError.errorFlag
                                             : Ci.nsIScriptError.warningFlag;
      const consoleMsg = Cc["@mozilla.org/scripterror;1"].createInstance(
        Ci.nsIScriptError
      );
      consoleMsg.init(joinedArguments, null, null, 0, 0, flag, "content javascript");

      Logger.debug("Content JS: " + aMessage.filename + ", function: " + functionName + ", message: " + consoleMsg);
    } else if (aMessage.level == "trace") {
      const filename = this._abbreviateSourceURL(aMessage.filename);
      const lineNumber = aMessage.lineNumber;

      Logger.debug("Content JS: " + filename + ", function: " + functionName + ", line: " + lineNumber + ", message: " + joinedArguments);
    } else {
      Logger.debug("Content JS: " + aMessage.filename + ", function: " + functionName + ", message: " + joinedArguments);
    }
  },

  _abbreviateSourceURL(aSourceURL) {
    // Remove any query parameters.
    const hookIndex = aSourceURL.indexOf("?");
    if (hookIndex > -1) {
      aSourceURL = aSourceURL.substring(0, hookIndex);
    }

    // Remove a trailing "/".
    if (aSourceURL[aSourceURL.length - 1] == "/") {
      aSourceURL = aSourceURL.substring(0, aSourceURL.length - 1);
    }

    // Remove all but the last path component.
    const slashIndex = aSourceURL.lastIndexOf("/");
    if (slashIndex > -1) {
      aSourceURL = aSourceURL.substring(slashIndex + 1);
    }

    return aSourceURL;
  },

  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver, Ci.nsISupportsWeakReference])
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([$EmbedLiteConsoleListener]);
