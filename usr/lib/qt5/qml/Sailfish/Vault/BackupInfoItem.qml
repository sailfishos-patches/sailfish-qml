/****************************************************************************************
**
** Copyright (c) 2020 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: root

    property alias sourceName: fileSourceLabel.text
    property var backupInfo
    property bool highlighted
    property var today
    readonly property string filePath: (backupInfo.fileDir ? backupInfo.fileDir + "/" : "") + backupInfo.fileName

    readonly property bool _useHighlightColor: !backupInfo || !backupInfo.fileName || highlighted || !enabled

    width: parent.width
    height: fileSourceLabel.y + fileSourceLabel.height + Theme.paddingMedium

    BusyIndicator {
        id: backupInfoBusy

        anchors {
            left: topRow.left
            verticalCenter: topRow.verticalCenter
        }
        size: BusyIndicatorSize.ExtraSmall
        running: !root.backupInfo.ready
    }

    Item {
        id: topRow

        anchors {
            top: parent.top
            topMargin: Theme.paddingMedium
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }

        height: nameLabel.height
        opacity: 1 - backupInfoBusy.opacity

        Label {
            id: errorLabel

            anchors.baseline: nameLabel.baseline
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: text == root.backupInfo.error
                            ? Theme.fontSizeExtraSmall
                            : Theme.fontSizeSmall
            text: {
                if (!!root.backupInfo.ready) {
                    if (!!root.backupInfo.error) {
                        return root.backupInfo.error
                    }
                    return root.backupInfo.fileName
                            ? ""
                              //: No previous backups were found on the cloud or memory card storage
                              //% "No previous backups found"
                            : qsTrId("vault-la-no_previous_backups_found")
                }
                return ""
            }
            color: root.backupInfo.error ? Theme.errorColor : Theme.highlightColor
        }

        Label {
            id: nameLabel

            width: parent.width - createdLabel.implicitWidth - Theme.paddingLarge
            truncationMode: TruncationMode.Fade
            text: root.backupInfo.fileName || ""
            color: root._useHighlightColor ? Theme.highlightColor : Theme.primaryColor
        }

        Label {
            id: createdLabel

            anchors.right: parent.right
            text: root.backupInfo.created !== undefined
                  ? Format.formatDate(root.backupInfo.created, (root.backupInfo.created.getFullYear() === today.getFullYear() ? Format.DateMediumWithoutYear : Format.DateMedium))
                    + " " + Format.formatDate(root.backupInfo.created, Format.TimeValue)
                  : ""
            color: root._useHighlightColor ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }
    }

    Label {
        id: fileSourceLabel

        anchors {
            top: topRow.bottom
            left: topRow.left
            right: topRow.right
        }

        text: model.name
        color: createdLabel.color
        font.pixelSize: Theme.fontSizeExtraSmall
    }
}
