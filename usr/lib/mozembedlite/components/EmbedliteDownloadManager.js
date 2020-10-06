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

Cu.import("resource://gre/modules/XPCOMUtils.jsm");

XPCOMUtils.defineLazyModuleGetter(this, "Downloads",
                                  "resource://gre/modules/Downloads.jsm");
XPCOMUtils.defineLazyModuleGetter(this, "Services",
                                  "resource://gre/modules/Services.jsm");
XPCOMUtils.defineLazyModuleGetter(this, "Task",
                                  "resource://gre/modules/Task.jsm");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

////////////////////////////////////////////////////////////////////////////////
//// DownloadViewer

let DownloadView = {
  // This is a map of download => their properties since the previos change
  prevState: {},
  counter: 0,

  onDownloadAdded: function(download) {
    this.counter++;
    this.prevState[download] = {
      id: this.counter,
      download: download,
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
                                       id: this.prevState[download].id,
                                       percent: download.progress
                                   }));
    }

    if (download.succeeded) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-done",
                                       id: this.prevState[download].id,
                                       targetPath: download.target.path
                                   }));
    }

    if (download.error) {
      Logger.warn("EmbedliteDownloadManager error:", download.error.message);
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-fail",
                                       id: this.prevState[download].id
                                   }));
    }

    if (download.canceled) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-cancel",
                                       id: this.prevState[download].id
                                   }));
    }
  },

  onDownloadChanged: function(download) {
    if (this.prevState[download].progress !== download.progress) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-progress",
                                       id: this.prevState[download].id,
                                       percent: download.progress
                                   }));
    }
    this.prevState[download].progress = download.progress;

    if (!this.prevState[download].succeeded && download.succeeded) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-done",
                                       id: this.prevState[download].id,
                                       targetPath: download.target.path
                                   }));
    }
    this.prevState[download].succeeded = download.succeeded;

    if (!this.prevState[download].error && download.error) {
      Logger.debug("EmbedliteDownloadManager error:", download.error.message);
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-fail",
                                       id: this.prevState[download].id
                                   }));
    }
    this.prevState[download].error = download.error;

    if (!this.prevState[download].canceled && download.canceled) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                       msg: "dl-cancel",
                                       id: this.prevState[download].id
                                   }));
    }
    this.prevState[download].canceled = download.canceled;

    if (this.prevState[download].stopped && !download.stopped) {
      Services.obs.notifyObservers(null, "embed:download",
                                   JSON.stringify({
                                     msg: "dl-start",
                                     id: this.prevState[download].id,
                                     displayName: download.target.path.split('/').slice(-1)[0],
                                     sourceUrl: download.source.url,
                                     targetPath: download.target.path,
                                     mimeType: download.contentType,
                                     size: download.totalBytes
                                   }));
    }
    this.prevState[download].stopped = download.stopped;
  },

  onDownloadRemoved: function(download) {
    delete this.prevState[download];
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

  QueryInterface: XPCOMUtils.generateQI([Ci.nsIObserver]),

  observe: function(aSubject, aTopic, aData) {
    switch (aTopic) {
      case "app-startup":
        Services.obs.addObserver(this, "profile-after-change", false);
        break;

      case "profile-after-change":
        Services.obs.removeObserver(this, "profile-after-change");
        Services.obs.addObserver(this, "embedui:download", false);
        Task.spawn(function() {
          let downloadList = yield Downloads.getList(Downloads.ALL);

          // Let's remove all existing downloads from the Download List
          // before adding the view so that partial (cancelled) downloads
          // will not get restarted.
          let list = yield downloadList.getAll();
          for (let download of list) {
            // No need to check if this is download has hasPartialData true or not
            // as we do not have download list at the browser side.
            yield downloadList.remove(download);
            download.finalize(true).then(null, Cu.reportError);
          }

          yield downloadList.addView(DownloadView);
        }).then(null, Cu.reportError);
        break;

      case "embedui:download":
        var data = JSON.parse(aData);

        switch (data.msg) {
          case "retryDownload":
            for (var key in DownloadView.prevState) {
              if (DownloadView.prevState[key].id === data.id) {
                DownloadView.prevState[key].download.start();
              }
            }
            break;

          case "cancelDownload":
            for (var key in DownloadView.prevState) {
              if (DownloadView.prevState[key].id === data.id) {
                // Switch to cancel (from finalize) so that we have partially downloaded hanging.
                // A partially downloaded download can be restarted during the same browsering
                // session. Restarting the browser will clear download list.
                DownloadView.prevState[key].download.cancel();
              }
            }
            break;

          case "addDownload":
            Task.spawn(function() {
              let list = yield Downloads.getList(Downloads.ALL);
              let download = yield Downloads.createDownload({
                source: data.from,
                target: data.to
              });
              download.start();
              list.add(download);
            }).then(null, Cu.reportError);
            break;

          case "saveAsPdf":
            if (Services.ww.activeWindow) {
              Task.spawn(function() {
                let list = yield Downloads.getList(Downloads.ALL);
                let download = yield Downloads.createDownload({
                  source: Services.ww.activeWindow,
                  target: data.to,
                  saver: "pdf",
                  contentType: "application/pdf"
                });
                download.start();
                list.add(download);
              }).then(null, Cu.reportError);
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
