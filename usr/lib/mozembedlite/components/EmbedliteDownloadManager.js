/* -*- indent-tabs-mode: nil; js-indent-level: 2 -*- */
/* vim: set ts=2 et sw=2 tw=80: */
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

"use strict";

////////////////////////////////////////////////////////////////////////////////
//// Globals

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cu = Components.utils;
const Cr = Components.results;

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");

XPCOMUtils.defineLazyModuleGetter(this, "Downloads",
                                  "resource://gre/modules/Downloads.jsm");
XPCOMUtils.defineLazyModuleGetter(this, "Services",
                                  "resource://gre/modules/Services.jsm");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

////////////////////////////////////////////////////////////////////////////////
//// DownloadViewer

let DownloadView = {
  // This is a map of download => their properties since the previos change
  counter: 0,

  onDownloadAdded: function(download) {
    this.counter++;

    if (download["id"]) {
      Logger.warn("Download id is already set")
    } else {
      download["id"] = this.counter;
    }

    if (download["prevState"]) {
      Logger.warn("Download prevState is already set")
    }

    download["prevState"] = {
      progress: download.progress,
      succeeded: download.succeeded,
      error: download.error,
      canceled: download.canceled,
      stopped: download.stopped
    };

    Services.obs.notifyObservers(null, "embed:download",
                                 JSON.stringify({
                                     msg: "dl-start",
                                     id: this.counter,
                                     saveAsPdf: download.saveAsPdf || false,
                                     displayName: download.target.path.split('/').slice(-1)[0],
                                     sourceUrl: download.source.url,
                                     targetPath: download.target.path,
                                     mimeType: download.contentType,
                                     size: download.totalBytes
                                 }));

    if (download.progress) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-progress",
                                       id: download.id,
                                       saveAsPdf: download.saveAsPdf || false,
                                       percent: download.progress
                                   }));
    }

    if (download.succeeded) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-done",
                                       id: download.id,
                                       saveAsPdf: download.saveAsPdf || false,
                                       targetPath: download.target.path
                                   }));
    }

    if (download.error) {
      Logger.warn("EmbedliteDownloadManager error:", download.error.message);
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-fail",
                                       id: download.id,
                                       saveAsPdf: download.saveAsPdf || false
                                   }));
    }

    if (download.canceled) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-cancel",
                                       id: download.id,
                                       saveAsPdf: download.saveAsPdf || false
                                   }));
    }
  },

  onDownloadChanged: function(download) {
    if (download.prevState.progress !== download.progress) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-progress",
                                       id: download.id,
                                       saveAsPdf: download.saveAsPdf || false,
                                       percent: download.progress
                                   }));
    }
    download.prevState.progress = download.progress;

    if (!download.prevState.succeeded && download.succeeded) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-done",
                                       id: download.id,
                                       saveAsPdf: download.saveAsPdf || false,
                                       targetPath: download.target.path
                                   }));
    }
    download.prevState.succeeded = download.succeeded;

    if (!download.prevState.error && download.error) {
      Logger.debug("EmbedliteDownloadManager error:", download.error.message);
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-fail",
                                       id: download.id,
                                       saveAsPdf: download.saveAsPdf || false
                                   }));
    }
    download.prevState.error = download.error;

    if (!download.prevState.canceled && download.canceled) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-cancel",
                                       id: download.id,
                                       saveAsPdf: download.saveAsPdf || false
                                   }));
    }
    download.prevState.canceled = download.canceled;

    if (download.prevState.stopped && !download.stopped) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                     msg: "dl-start",
                                     id: download.id,
                                     saveAsPdf: download.saveAsPdf || false,
                                     displayName: download.target.path.split('/').slice(-1)[0],
                                     sourceUrl: download.source.url,
                                     targetPath: download.target.path,
                                     mimeType: download.contentType,
                                     size: download.totalBytes
                                   }));
    }
    download.prevState.stopped = download.stopped;
  }
};

////////////////////////////////////////////////////////////////////////////////
//// EmbedliteDownloadManager

function EmbedliteDownloadManager()
{
  Logger.debug("JSComp: EmbedliteDownloadManager.js loaded");
}

EmbedliteDownloadManager.prototype = {
  classID: Components.ID("{71b0a6e8-83ac-4006-af97-d66009db97c8}"),

  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver]),

  observe: function(aSubject, aTopic, aData) {
    switch (aTopic) {
      case "app-startup":
        Services.obs.addObserver(this, "profile-after-change", false);
        break;

      case "profile-after-change":
        Services.obs.removeObserver(this, "profile-after-change");
        Services.obs.addObserver(this, "embedui:download", false);
        (async function() {
          let downloadList = await Downloads.getList(Downloads.ALL);

          // Let's remove all existing downloads from the Download List
          // before adding the view so that partial (cancelled) downloads
          // will not get restarted.
          let list = await downloadList.getAll();
          for (let download of list) {
            // No need to check if this is download has hasPartialData true or not
            // as we do not have download list at the browser side.
            await downloadList.remove(download);
            download.finalize(true).then(null, Cu.reportError);
          }

          await downloadList.addView(DownloadView);
        })().then(null, Cu.reportError);
        break;

      case "embedui:download":
        var data = JSON.parse(aData);

        switch (data.msg) {
          case "retryDownload":
            (async function() {
              let downloadList = await Downloads.getList(Downloads.ALL);
              let list = await downloadList.getAll();
              for (let download of list) {
                if (download.id === data.id) {
                  download.start();
                  break;
                }
              }
            })().then(null, Cu.reportError);
            break;

          case "cancelDownload":
            (async function() {
              let downloadList = await Downloads.getList(Downloads.ALL);
              let list = await downloadList.getAll();
              for (let download of list) {
                if (download.id === data.id) {
                  // Switch to cancel (from finalize) so that we have partially downloaded hanging.
                  // A partially downloaded download can be restarted during the same browsering
                  // session. Restarting the browser will clear download list.
                  download.cancel();
                  break;
                }
              }
            })().then(null, Cu.reportError);
            break;

          case "addDownload":
            (async function() {
              let list = await Downloads.getList(Downloads.ALL);
              let download = await Downloads.createDownload({
                source: data.from,
                target: data.to
              });
              download.start();
              list.add(download);
            })().then(null, Cu.reportError);
            break;

          case "saveAsPdf":
            if (Services.ww.activeWindow) {
              (async function() {
                let list = await Downloads.getList(Downloads.ALL);
                let download = await Downloads.createDownload({
                  source: Services.ww.activeWindow,
                  target: data.to,
                  saver: "pdf",
                  contentType: "application/pdf"
                });
                download["saveAsPdf"] = true;
                download.start();
                list.add(download);
              })().then(null, Cu.reportError);
            } else {
              Logger.warn("No active window to print to pdf")
            }
            break;
        }
        break;
    }
  }
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([EmbedliteDownloadManager]);
