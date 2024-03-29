/****************************************************************************************
**
** Copyright (C) 2019 Open Mobile Platform LLC
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/
import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import Sailfish.Share 1.0
import Sailfish.TransferEngine 1.0

ShareFilePreview {
    id: root

    imageScaleVisible: false
    descriptionVisible: false
    metaDataSwitchVisible: false

    remoteDirName: account.savedRemoteDirName
    remoteDirReadOnly: false

    Connections {
        target: root.sailfishAction || null

        onDone: {
            if (account.updateShareConfig()) {
                // Do blocking sync, else the sync may not finish before the object is destroyed.
                account.blockingSync()
            }
        }
    }

    Account {
        id: account

        readonly property string imagesDirKey: "share_images_dir"
        readonly property string otherFilesDirKey: "share_other_files_dir"
        readonly property string dirConfigKey: (root.fileInfo.mimeFileType === "image")
                                               ? imagesDirKey
                                               : otherFilesDirKey

        property string savedRemoteDirName

        function updateShareConfig() {
            if (savedRemoteDirName === root.remoteDirName) {
                return false
            }
            var config = configurationValues("nextcloud-sharing")
            var value = config[dirConfigKey]
            setConfigurationValue("nextcloud-sharing", dirConfigKey, root.remoteDirName)
            return true
        }

        identifier: root.sailfishTransfer.transferMethodInfo.accountId

        onStatusChanged: {
            if (status === Account.Initialized) {
                var config = configurationValues("nextcloud-sharing")
                var savedValue = config[dirConfigKey]
                account.savedRemoteDirName = (savedValue === undefined)
                        ? (root.fileInfo.mimeFileType === "image"
                          ? "Photos"
                          : "Documents")
                        : savedValue

            }
        }
    }
}

