/****************************************************************************
**
** Copyright (c) 2013-2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
** License: Proprietary
**
****************************************************************************/
import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.sailfishos 1.0
import org.nemomobile.ofono 1.0
import Sailfish.Vault 1.0

Column {
    // Update info
    property bool backupEnabled: backupSwitch.checked && storagePicker.selectionValid
    property int horizontalMargin: Theme.horizontalPageMargin
    property bool haveVoiceCalls: modemManager.enabledModems.length > 0
    property BackupRestoreStoragePicker backupStoragePicker: storagePicker

    anchors {
        left: parent.left
        right: parent.right
    }

    OfonoModemManager {
        id: modemManager
    }

    Label {
        x: horizontalMargin
        width: Math.min(implicitWidth, parent.width - 2*x - busyIndicator.width - busyIndicator.anchors.leftMargin)
        text: {
            if (storeIf.updateStatus === StoreInterface.UpToDate) {
                //: System update check status text
                //% "Up to date"
                return qsTrId("settings_sailfishos-la-up_to_date")
            } else if (storeIf.updateStatus === StoreInterface.UpdateAvailable) {
                if (storeIf.updateProgress === 0) {
                    if (storeIf.osDownloadSize > 0) {
                        //: System update check status text, takes size as a parameter
                        //% "Update available for download (%1)"
                        return qsTrId("settings_sailfishos-la-update_available_with_size")
                            .arg(Format.formatFileSize(storeIf.osDownloadSize, 0))
                    } else {
                        //: System update check status text
                        //% "Update available for download"
                        return qsTrId("settings_sailfishos-la-update_available")
                    }
                } else if (storeIf.updateProgress === 100) {
                    //: System update check status text
                    //% "Update ready to be installed"
                    return qsTrId("settings_sailfishos-la-ready_to_install")
                } else {
                    //: System update check status text
                    //% "Downloading update"
                    return qsTrId("settings_sailfishos-la-downloading")
                }
            } else if (storeIf.updateStatus === StoreInterface.WaitingForConnection) {
                //: System update check status text
                //% "Waiting for connection"
                return qsTrId("settings_sailfishos-la-waiting_for_connection")
            } else if (storeIf.updateStatus === StoreInterface.Checking) {
                //: System update check status text
                //% "Checking for updates"
                return qsTrId("settings_sailfishos-la-checking")
            } else if (storeIf.updateStatus === StoreInterface.PreparingForUpdate) {
                //: System update size check status text
                //% "Preparing for update"
                return qsTrId("settings_sailfishos-la-preparing_for_update")
            } else {
                return ""
            }
        }
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap

        BusyIndicator {
            id: busyIndicator

            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.right
                leftMargin: Theme.paddingMedium
            }
            running: storeIf.updateStatus === StoreInterface.PreparingForUpdate
                     || storeIf.downloading
            size: BusyIndicatorSize.ExtraSmall
        }
    }

    Label {
        x: horizontalMargin
        //: Time elapsed since last update check. Takes a timestamp as a
        //: parameter (in format 'N minutes/hours/days ago').
        //: Notice that the timestamp localization expects that it's in the
        //: beginning of a sentence, thus a colon is needed after "Last checked".
        //% "Last checked: %1"
        text: qsTrId("settings_sailfishos-la-last_checked").arg(
                  Format.formatDate(storeIf.lastChecked, Formatter.DurationElapsed))
        color: Theme.secondaryHighlightColor
        font.pixelSize: Theme.fontSizeExtraSmall
        visible: (storeIf.updateStatus === StoreInterface.UpToDate ||
                  storeIf.haveUpgrade) &&
                 storeIf.checked
    }

    Item {
        width: 1
        height: Theme.paddingMedium
        visible: storeIf.haveDetails
    }

    UpgradeSummary {
    }

    Item {
        visible: releaseNotesLabel.visible
        width: 1
        height: Theme.paddingMedium
    }

    Text {
        id: releaseNotesLabel
        anchors.right: parent.right
        anchors.rightMargin: horizontalMargin
        visible: storeIf.osWebsite !== "" &&
                 storeIf.haveDetails &&
                 !storeIf.downloaded

        color: Theme.primaryColor
        linkColor: Theme.primaryColor
        font.pixelSize: Theme.fontSizeExtraSmall
        textFormat: Text.StyledText
        text: "<a href=\"" + storeIf.osWebsite + "\">" +
              //: Link to release notes web page
              //% "Release notes"
              qsTrId("settings_sailfishos-la-release_notes") +
              "</a>"

        onLinkActivated: {
            Qt.openUrlExternally(link)
        }
    }

    Item {
        width: 1
        height: Theme.paddingMedium
        visible: storagePicker.visible
    }

    SectionHeader {
        id: backupSection
        visible: storeIf.haveDetails && storeIf.updateProgress === 0
        //: Data backup details
        //% "Backup"
        text: qsTrId("settings_sailfishos-la-backup")
    }

    Label {
        x: horizontalMargin
        width: parent.width - x*2
        wrapMode: Text.Wrap
        visible: backupSection.visible && !storagePicker.selectionValid
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.highlightColor

        //% "No backup services available. To allow backups, insert a memory card or add a cloud storage account in Settings | Accounts."
        text: qsTrId("settings_sailfishos-la-no_backup_services_available")
    }

    TextSwitch {
        id: backupSwitch
        width: parent.width
        visible: backupSection.visible && storagePicker.selectionValid
        enabled: AccessPolicy.osUpdatesEnabled

        //: Text for backup switch
        //% "Make backup"
        text: qsTrId("settings_sailfishos-la-backup_switch")

        //: Description text for backup switch
        //% "You can backup your device while downloading the update"
        description: qsTrId("settings_sailfishos-la-backup_description")

        onCheckedChanged: {
            heightAnim.enabled = true
        }
    }

    Item {
        width: 1
        height: Theme.paddingMedium
        visible: !backupSwitch.visible
    }

    Item {
        width: parent.width
        height: backupSwitch.visible && backupSwitch.checked ? storagePicker.height : 0
        opacity: backupSwitch.visible && backupSwitch.checked ? 1 : 0
        clip: true

        Behavior on opacity { FadeAnimation { } }
        Behavior on height {
            id: heightAnim
            NumberAnimation {
                duration: 150
                onRunningChanged: {
                    if (!running) {
                        // don't animate when picker combobox opens/closes
                        heightAnim.enabled = false
                    }
                }
            }
        }

        BackupRestoreStoragePicker {
            id: storagePicker
            backupMode: true
            leftMargin: contentMargin
            rightMargin: contentMargin
            enabled: AccessPolicy.osUpdatesEnabled
        }
    }
}
