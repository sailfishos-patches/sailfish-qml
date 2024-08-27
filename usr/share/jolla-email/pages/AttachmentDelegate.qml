/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Thumbnailer 1.0
import Nemo.Email 0.1
import Nemo.FileManager 1.0

BackgroundItem {
    id: attachmentItem

    readonly property bool activated: statusInfo === EmailAgent.Downloading || statusInfo === EmailAgent.Queued
    readonly property bool downloaded: statusInfo === EmailAgent.Downloaded && url !== ""
    readonly property int downloadedSize: progressInfo * size
    property bool openOnDownload
    property real attachmentNameFontSize: Theme.fontSizeMedium
    property real attachmentStatusFontSize: Theme.fontSizeSmall

    property real leftMargin: Theme.horizontalPageMargin
    property real rightMargin: Theme.horizontalPageMargin

    function triggerAction(url) {
        // Attachment is considered as downloaded when attachment body has been
        // downloaded. The url is only valid when attachment exists also in file system.
        if (url && statusInfo === EmailAgent.Downloaded) {
            if (mimeType.toLowerCase() == "message/rfc822") {
                pageStack.animatorPush(app.getMessageViewerComponent(), { "pathToLoad": FileEngine.urlToPath(url) })
            } else {
                Qt.openUrlExternally(url)
            }
            return true
        } else {
            return false
        }
    }

    onClicked: {
        if (activated) {
            openOnDownload = false
            emailAgent.cancelAttachmentDownload(contentLocation)
        } else if (!triggerAction(url)) {
            // maybe downloaded but not saved as file
            var saved = emailAgent.downloadAttachment(messageId, contentLocation)
            if (saved) {
                triggerAction(url)
            } else {
                openOnDownload = true
            }
        }
    }

    onDownloadedChanged: {
        if (downloaded && openOnDownload) {
            openOnDownload = false

            triggerAction(url)
        }
    }

    Thumbnail {
        id: icon
        x: attachmentItem.leftMargin
        y: (attachmentItem.contentHeight - height) / 2
        height: Theme.iconSizeMedium
        width: Theme.iconSizeMedium

        sourceSize.width: width
        sourceSize.height: height
        source: url
        mimeType: mimeType
    }

    Icon {
        visible: icon.status !== Thumbnail.Ready
        anchors.centerIn: icon
        source: activated ? "image://theme/icon-m-clear" : Theme.iconForMimeType(mimeType)

        Loader {
            active: attachmentItem.activated
            anchors.centerIn: parent
            sourceComponent: ProgressCircle {
                value: statusInfo === EmailAgent.Downloading ? progressInfo : 0
                height: attachmentItem.contentHeight - 2*Theme.paddingSmall
                width: height
                progressColor: Theme.highlightDimmerColor
                backgroundColor: attachmentItem.pressed ? Theme.secondaryHighlightColor : Theme.highlightColor
            }
        }
    }

    Label {
        id: attachmentName

        x: icon.x + icon.width + Theme.paddingMedium
        y: Math.max(Theme.paddingLarge, (attachmentItem.contentHeight - height) / 2)
        width: sizeLabel.x - x - Theme.paddingMedium

        font.pixelSize: attachmentItem.attachmentNameFontSize

        text: type === AttachmentListModel.Email
            //: Attached email with unknown title => use placeholder name
            //% "Forwarded email"
            ? title || qsTrId("jolla-email-la-forwarded_email")
            : displayName
        truncationMode: TruncationMode.Fade
    }

    Label {
        id: sizeLabel
        x: attachmentItem.width - width - attachmentItem.rightMargin
        y: Math.max(Theme.paddingLarge, (attachmentItem.contentHeight - height) / 2)

        text: statusInfo === EmailAgent.Downloading
                ? (Format.formatFileSize(downloadedSize, 2)
                    + "/"
                    + Format.formatFileSize(size, 2))
                : Format.formatFileSize(size, 2)
        font.pixelSize: attachmentStatusFontSize
    }
}
