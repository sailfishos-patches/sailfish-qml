/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

const Cc = Components.classes;
const Ci = Components.interfaces;
const Cu = Components.utils;
const Cr = Components.results;

const PREF_BD_USEDOWNLOADDIR = "browser.download.useDownloadDir";
const URI_GENERIC_ICON_DOWNLOAD = "drawable://alert_download";

Cu.import("resource://gre/modules/XPCOMUtils.jsm");
Cu.import("resource://gre/modules/Services.jsm");
Cu.import("resource://gre/modules/Task.jsm");

ChromeUtils.import("resource://gre/modules/DownloadPaths.jsm");
ChromeUtils.import("resource://gre/modules/Downloads.jsm");
ChromeUtils.import("resource://gre/modules/FileUtils.jsm");

Services.scriptloader.loadSubScript("chrome://embedlite/content/Logger.js");

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
  QueryInterface: XPCOMUtils.generateQI([Ci.nsIHelperAppLauncherDialog]),

  show: function hald_show(aLauncher, aContext, aReason) {
    // Check to see if we can open this file or not
    Logger.debug("HelperAppLauncherDialog show");

    // See nsIMIMEInfo.idl, nsIExternalHelperAppService and uriloader/exthandler/nsExternalHelperAppService.cpp
    // For now save them all.

//    if (aLauncher.MIMEInfo.hasDefaultHandler) {
//      aLauncher.MIMEInfo.preferredAction = Ci.nsIMIMEInfo.useSystemDefault;
//      aLauncher.launchWithApplication(null, false);
//    }
    aLauncher.saveToDisk(null, false);
  },

  promptForSaveToFileAsync: function hald_promptForSaveToFileAsync(aLauncher, aWindowContext, aDefaultFileName,
                                  aSuggestedFileExtension,
                                  aForcePrompt) {
    Logger.debug("HelperAppLauncherDialog promptForSaveToFileAsync");

    let file = null;
    this.mLauncher = aLauncher;

    (async () => {
       // Retrieve the user's default download directory
       let preferredDir = await Downloads.getPreferredDownloadsDirectory();
       let defaultFolder = new FileUtils.File(preferredDir);
       try {
         file = this.validateLeafName(defaultFolder, aDefaultFileName,
                                      aSuggestedFileExtension);
       } catch (e) {
         // When the default download directory is write-protected,
         // prompt the user for a different target file.
         Logger.warn(e);
       }

       // Check to make sure we have a valid directory, otherwise, prompt
       if (file) {
         // This path is taken when we have a writable default download directory.
         aLauncher.saveDestinationAvailable(file);
       }
     })().catch(Cu.reportError);
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
  }
};

this.NSGetFactory = XPCOMUtils.generateNSGetFactory([HelperAppLauncherDialog]);
