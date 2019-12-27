import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.sailfishos 1.0

Image {
    id: root

    property bool charging

    width: parent.width
    height: parent.width * .5
    source: storeIf.osCover

    Item {
        anchors.fill: parent

        PageHeader {
            //: Page header for the system update page
            //% "Sailfish OS"
            title: qsTrId("settings_sailfishos-he-sailfishos")
            _titleItem.color: Theme.lightPrimaryColor

            Label {
                anchors {
                    right: parent._titleItem.right
                    top: parent._titleItem.bottom
                }
                text: storeIf.osCodeName
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.lightPrimaryColor
            }
        }

        Label {
            visible: storeIf.osVersion !== ""
            anchors {
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                bottom: parent.bottom
                bottomMargin: Theme.paddingMedium
            }
            //: System update version heading text
            //% "Version %1"
            text: qsTrId("settings_sailfishos-la-version").arg(storeIf.osVersion)
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.lightPrimaryColor
        }

        Rectangle {
            property int percentage: attentionIcon.visible
                                     ? 0
                                     : storeIf.updateStatus !== StoreInterface.UpdateAvailable
                                       ? 100
                                       : storeIf.updateProgress

            anchors.right: parent.right
            height: parent.height
            width: (100 - percentage) * parent.width / 100
            color: "black"
            opacity: attentionIcon.visible ? Theme.opacityHigh : Theme.opacityLow

            // Show the dimmer on top of the "header texts" if we need to
            // show the battery or disk low indication.
            z: attentionIcon.visible ? 0 : -1

            Behavior on width {
                enabled: storeIf.downloading
                NumberAnimation { duration: 100 }
            }
        }
    }

    Image {
        id: attentionIcon
        visible: (storeIf.downloaded && (!storeIf.sufficientBatteryForInstall || !storeIf.diskOk))
                 || (storeIf.haveUpgrade && (!storeIf.sufficientBatteryForDownload || !storeIf.diskOk))
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        source: (!storeIf.diskOk
                ? "image://theme/icon-l-attention?"
                : "image://theme/icon-l-battery?") + Theme.lightPrimaryColor
    }

    Column {
        visible: attentionIcon.visible
        anchors {
            left: attentionIcon.right
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }

        Label {
            width: parent.width
            height: Math.min((root.height - 2*Theme.paddingSmall) * (freeSpaceHint.visible ? 0.6 : 1.0), implicitHeight)
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.highlightFromColor(Theme.highlightColor, Theme.LightOnDark)
            wrapMode: Text.Wrap
            fontSizeMode: Text.Fit
            text: {
                if (!storeIf.diskOk) {
                    var diskLowText = storeIf.downloaded
                    //: Disk space low warning for system update installation.
                    //: Takes required and currently available disk space values as parameters.
                    //% "Installing the update requires %1 free space. Currently %2 available."
                            ? qsTrId("settings_sailfishos-install_disk_space_low")
                              //: Disk space low warning for system update downloading.
                              //: Takes required and currently available disk space values as parameters.
                              //% "Downloading the update requires %1 free space. Currently %2 available."
                            : qsTrId("settings_sailfishos-download_disk_space_low")
                    return diskLowText
                    .arg(Format.formatFileSize(storeIf.requiredDisk, 0))
                    .arg(Format.formatFileSize(storeIf.availableDisk, 0))
                } else {
                    return charging
                    //: Battery low warning for system update installation when charger is attached.
                    //% "Battery level low. Do not remove the charger."
                            ? qsTrId("settings_sailfishos-la-battery_charging")
                              //: Battery low warning for system update installation when charger is not attached.
                              //% "Battery level too low."
                            : qsTrId("settings_sailfishos-la-battery_level_low")
                }
            }
        }

        Label {
            id: freeSpaceHint

            //% "Free up space on your device"
            readonly property string title:  qsTrId("settings_sailfishos-la-free_device_space")
            readonly property string url: "https://sailfishos.org/article/free-space-on-device"

            width: parent.width
            height: Math.min((root.height - 2*Theme.paddingSmall) * 0.4, implicitHeight)
            visible: !storeIf.diskOk
            opacity: !storeIf.diskOk && !storeIf.downloaded ? 1.0 : 0.0

            color: Theme.highlightFromColor(Theme.highlightColor, Theme.LightOnDark)
            linkColor: Theme.lightPrimaryColor
            textFormat: Text.StyledText
            text: "<a href='" + url + "'>" + title +"</a>"
            wrapMode: Text.WordWrap
            fontSizeMode: Text.Fit

            onLinkActivated: Qt.openUrlExternally(link)

            Behavior on opacity { FadeAnimation {} }
        }
    }

    DownloadUpgradeHint { }
}
