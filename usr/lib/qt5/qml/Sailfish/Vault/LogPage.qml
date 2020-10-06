/****************************************************************************************
**
** Copyright (c) 2020 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Vault 1.0

Page {
    id: root

    property string filePath

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height

        PullDownMenu {
            MenuItem {
                //% "Copy to clipboard"
                text: qsTrId("vault-me-copy_to_clipboard")
                onClicked: {
                    Clipboard.text = logContentLabel.text
                }
            }
        }

        VerticalScrollDecorator {}

        Column {
            id: contentColumn

            width: parent.width
            spacing: Theme.paddingLarge
            bottomPadding: Theme.paddingLarge

            PageHeader {
                //: Indicates this page contains contents of a backup log file
                //% "Backup log"
                title: qsTrId("vault-he-backup_log")
                description: {
                    var fileName = root.filePath.substring(root.filePath.lastIndexOf('/') + 1)
                    return fileName.substring(0, fileName.lastIndexOf('.'))
                }
                descriptionWrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Label {
                id: logContentLabel

                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin*2
                text: BackupUtils.readFile(root.filePath)
                wrapMode: Text.WrapAnywhere
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin*2
                //: Shows file system path of log file
                //% "Log file: %1"
                text: qsTrId("vault-la-log_file").arg(root.filePath)
                truncationMode: TruncationMode.None
                wrapMode: Text.WrapAnywhere
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}
