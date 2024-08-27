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
import Nemo.DBus 2.0

Column {
    // Update info
    property int horizontalMargin: Theme.horizontalPageMargin
    property bool haveVoiceCalls: modemManager.enabledModems.length > 0

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
                  Format.formatDate(storeIf.lastChecked, Formatter.TimeElapsed))
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

    Column {
        width: parent.width

        SectionHeader {
            //: Data backup details
            //% "Backup"
            text: qsTrId("settings_sailfishos-la-backup")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - Theme.horizontalPageMargin*2
            height: implicitHeight + Theme.paddingSmall
            wrapMode: Text.Wrap
            //% "We recommend that you make a backup prior to updating your device."
            text: qsTrId("settings_sailfishos-la-recommend_make_backup")
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeSmall
        }

        BackgroundItem {
            height: Math.max(implicitHeight, backupLinkLabel.height + 2*Theme.paddingSmall)
            onClicked: {
                pageStack.animatorPush("Sailfish.Vault.BackupPage")
            }

            Icon {
                id: backupIcon

                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                source: "image://theme/icon-m-backup"
            }

            Label {
                id: backupLinkLabel
                anchors {
                    left: backupIcon.right
                    leftMargin: Theme.paddingMedium
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                //% "Open backup settings"
                text: qsTrId("settings_sailfishos-la-go_to_backup")
                wrapMode: Text.Wrap
            }
        }

        DBusInterface {
            id: settingsApp

            service: "com.jolla.settings"
            path: "/com/jolla/settings/ui"
            iface: "com.jolla.settings.ui"
        }
    }
}
