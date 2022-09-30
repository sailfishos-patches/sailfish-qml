/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cu = Components.utils;
const Cr = Components.results;

const PREF_BD_USEDOWNLOADDIR = "browser.download.useDownloadDir";
const PREF_BD_DOWNLOADDIR = "browser.download.dir";
const URI_GENERIC_ICON_DOWNLOAD = "drawable://alert_download";

const { XPCOMUtils } = ChromeUtils.import("resource://gre/modules/XPCOMUtils.jsm");
const { Services } = ChromeUtils.import("resource://gre/modules/Services.jsm");

const { DownloadPaths } = ChromeUtils.import("resource://gre/modules/DownloadPaths.jsm");
const { Downloads } = ChromeUtils.import("resource://gre/modules/Downloads.jsm");
const { FileUtils } = ChromeUtils.import("resource://gre/modules/FileUtils.jsm");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

XPCOMUtils.defineLazyServiceGetter(Services, "embedlite",
                                    "@mozilla.org/embedlite-app-service;1",
                                    "nsIEmbedAppService");
///////////////////////////////////////////////////////////////////////////////
//// Helper Functions

/**
 * Determines if a given directory is able to be used to download to.
 *
 * @param aDirectory
 *        The directory to check.
 * @return true if we can use the directory, false otherwise.
 */
function isUsableDirectory(aDirectory)
{
  return aDirectory.exists() && aDirectory.isDirectory() &&
         aDirectory.isWritable();
}

// -----------------------------------------------------------------------
// HelperApp Launcher Dialog
// -----------------------------------------------------------------------

function HelperAppLauncherDialog() {
  Logger.debug("JSComp: HelperAppDialog.js loaded");
  // Initialize data properties.
  this.mLauncher = null;
}

HelperAppLauncherDialog.prototype = {
  classID: Components.ID("{e9d277a0-268a-4ec2-bb8c-10fdf3e44611}"),
  QueryInterface: ChromeUtils.generateQI([Ci.nsIHelperAppLauncherDialog], [Ci.nsIObserver]),

  observe: function(aSubject, aTopic, aData) {
        switch (aTopic) {
        case "embedui:downloadpicker":
            this.saveAndDownload(JSON.parse(aData));
            break;
        }
  },

  show: function hald_show(aLauncher, aContext, aReason) {
    // Check to see if we can open this file or not
    Logger.debug("HelperAppLauncherDialog show");

    // See nsIMIMEInfo.idl, nsIExternalHelperAppService and uriloader/exthandler/nsExternalHelperAppService.cpp
    // For now save them all.

//    if (aLauncher.MIMEInfo.hasDefaultHandler) {
//      aLauncher.MIMEInfo.preferredAction = Ci.nsIMIMEInfo.useSystemDefault;
//      aLauncher.launchWithApplication(null, false);
//    }
    aLauncher.promptForSaveDestination();
  },

  promptForSaveToFileAsync: function hald_promptForSaveToFileAsync(aLauncher, aWindowContext, aDefaultFileName,
                                  aSuggestedFileExtension,
                                  aForcePrompt) {
    this.mLauncher = aLauncher;
    Services.obs.addObserver(this, "embedui:downloadpicker", false);

    var result = {
      defaultFileName: aDefaultFileName,
      suggestedFileExtension: aSuggestedFileExtension
    }
    if (!aForcePrompt) {
      let autodownload = Services.prefs.getBoolPref(PREF_BD_USEDOWNLOADDIR, false);

      if (autodownload) {
        try {
          result.downloadDirectory = Services.prefs.getStringPref(PREF_BD_DOWNLOADDIR);
        } catch (e) {
          Logger.warn("HelperAppDialog: browser.download.dir isn't enabled, will use prefferedDir", e)
        }
        this.saveAndDownload(result);
        return;
      }
    }
    try {
      let winId = Services.embedlite.getIDByWindow(Services.ww.activeWindow);
      Services.embedlite.sendAsyncMessage(winId, "embed:downloadpicker", JSON.stringify(result));
    } catch (e) {
      Logger.warn("HelperAppDialog: sending async message failed", e)
    }
  },

  promptForSaveToFile: function hald_promptForSaveToFile(aLauncher, aContext, aDefaultFile, aSuggestedFileExt, aForcePrompt) {
    Logger.debug("HelperAppLauncherDialog promptForSaveToFile -- not supported");
    throw Cr.NS_ERROR_NOT_AVAILABLE;
  },

  getFinalLeafName: function (aLeafName, aFileExt) {
    return DownloadPaths.sanitize(aLeafName) ||
        "unnamed" + (aFileExt ? "." + aFileExt : "");
  },

  validateLeafName: function hald_validateLeafName(aLocalFolder, aLeafName, aFileExt) {
    Logger.debug("HelperAppLauncherDialog validateLeafName");

    if (!(aLocalFolder && isUsableDirectory(aLocalFolder))) {
      throw new Components.Exception("Destination directory non-existing or permission error",
                                     Cr.NS_ERROR_FILE_ACCESS_DENIED);
    }

    aLeafName = this.getFinalLeafName(aLeafName, aFileExt);
    aLocalFolder.append(aLeafName);

    // The following assignment can throw an exception, but
    // is now caught properly in the caller of validateLeafName.
    var createdFile = DownloadPaths.createNiceUniqueFile(aLocalFolder);

    return createdFile;
  },

  _notify: function hald_notify(aLauncher, aCallback) {
    let notifier = Cc[aCallback ? "@mozilla.org/alerts-service;1" : "@mozilla.org/toaster-alerts-service;1"].getService(Ci.nsIAlertsService);
    notifier.showAlertNotification(URI_GENERIC_ICON_DOWNLOAD,
                                   "alertDownloads",
                                   "alertCantOpenDownload",
                                   true, "", aCallback, "downloadopen-fail");
  },
  saveAndDownload: function(data) {
    let file = null;

    (async () => {
      let prefferedDir = data.downloadDirectory;
      let downloadFolder = new FileUtils.File(prefferedDir);
      if (!isUsableDirectory(downloadFolder)) {
        prefferedDir = await Downloads.getPreferredDownloadsDirectory();
        downloadFolder = new FileUtils.File(prefferedDir);
      }
      try {
        file = this.validateLeafName(downloadFolder, data.defaultFileName,
                                     data.suggestedFileExtension);
      } catch (e) {
        // When the default download directory is write-protected,
        // prompt the user for a different target file.
        Logger.warn(e);
      }

      if (file && this.mLauncher) {
        this.mLauncher.saveDestinationAvailable(file);
      }
      Services.obs.removeObserver(this, "embedui:downloadpicker", true);
    })().catch(Cu.reportError);
  },
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([HelperAppLauncherDialog]);
