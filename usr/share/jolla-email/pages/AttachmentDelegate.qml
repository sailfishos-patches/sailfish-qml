/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.thumbnailer 1.0
import Nemo.Email 0.1

BackgroundItem {
    id: root

    property real leftMargin
    property real rightMargin: Theme.horizontalPageMargin
    property real iconSize: root.height
    property real attachmentNameFontSize: Theme.fontSizeMedium
    property real attachmentStatusFontSize: Theme.fontSizeSmall
    property real spacing: Theme.paddingLarge + Theme.paddingSmall
    // estimate, exact value not available from qmf. furthermore it's email data size, not file size.
    readonly property int downloadedSize: progressInfo * size
    readonly property bool activated: statusInfo === EmailAgent.Downloading || statusInfo === EmailAgent.Queued
    readonly property real maxStatusOpacity: (statusInfo === EmailAgent.Queued || statusInfo === EmailAgent.NotDownloaded) ? Theme.opacityHigh : 1.0

    function triggerAction(url) {
        // Attachment is considered as downloaded when attachment body has been
        // downloaded. The url is only valid when attachment exists also in file system.
        if (url && statusInfo === EmailAgent.Downloaded) {
            if (mimeType.toLowerCase() == "message/rfc822") {
                pageStack.animatorPush(app.getMessageViewerComponent(), { "pathToLoad": url });
            } else {
                Qt.openUrlExternally("file://" + url)
            }
            return true
        } else {
            return false
        }
    }

    onClicked: {
        if (activated) {
            emailAgent.cancelAttachmentDownload(contentLocation)
        } else if (!triggerAction(url)) {
            // maybe downloaded but not saved as file
            var saved = emailAgent.downloadAttachment(messageId, contentLocation)
            if (saved) {
                triggerAction(url)
            }
        }
    }

    contentHeight: Theme.itemSizeMedium
    height: contentItem.height

    Thumbnail {
        id: icon
        x: leftMargin
        visible: url != "" && status !== Thumbnail.Null && status !== Thumbnail.Error
        height: iconSize
        width: height
        anchors.verticalCenter: parent.verticalCenter
        sourceSize.width: width
        sourceSize.height: height
        source: url != "" ? "file://" + url : ""
        mimeType: mimeType
    }

    Image {
        visible: !icon.visible
        anchors.centerIn: icon
        source: (activated ? "image://theme/icon-m-clear" : Theme.iconForMimeType(mimeType))
                + "?" + (highlighted ? Theme.highlightColor : Theme.primaryColor)

        Loader {
            active: activated
            anchors.centerIn: parent
            sourceComponent: ProgressCircle {
                value: statusInfo === EmailAgent.Downloading ? progressInfo : 0
                height: root.contentHeight - 2*Theme.paddingSmall
                width: height
                progressColor: Theme.highlightDimmerColor
                backgroundColor: root.pressed ? Theme.secondaryHighlightColor : Theme.highlightColor
            }
        }
    }

    Item {
        anchors {
            left: icon.right
            leftMargin: Theme.paddingMedium
            right: root.contentItem.right
            rightMargin: root.rightMargin
            verticalCenter: parent.verticalCenter
        }
        height: attachmentStatusLabel.y + attachmentStatusLabel.height

        Label {
            id: attachmentName

            font.pixelSize: attachmentNameFontSize
            width: parent.width
            text: type == AttachmentListModel.Email
                //: Attached email with unknown title => use placeholder name
                //% "Forwarded email"
                ? title || qsTrId("jolla-email-la-forwarded_email")
                : displayName
            color: highlighted ? Theme.highlightColor : Theme.primaryColor
            opacity: maxStatusOpacity
            truncationMode: TruncationMode.Fade
        }

        Label {
            id: attachmentStatusLabel
            property bool crossFade: contentWidth + sizeLabel.width + Theme.paddingMedium > parent.width
            property real statusOpacity: maxStatusOpacity
            SequentialAnimation on statusOpacity {
                running: ((statusInfo === EmailAgent.NotDownloaded) || (statusInfo === EmailAgent.Downloaded)) && attachmentStatusLabel.crossFade
                loops: Animation.Infinite
                PauseAnimation { duration: 5000 }
                NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad; to: 0.0 }
                PauseAnimation { duration: 5000 }
                NumberAnimation { duration: 1000; easing.type: Easing.InOutQuad; to: maxStatusOpacity }
            }
            opacity: crossFade ? statusOpacity : maxStatusOpacity
            visible: text != ""

            truncationMode: TruncationMode.Fade
            width: parent.width
            anchors {
                baseline: attachmentName.baseline
                baselineOffset: root.spacing
            }
            font.pixelSize: attachmentStatusFontSize

            text: attachmentStatus(statusInfo)
            color: highlighted ? Theme.highlightColor : Theme.primaryColor

            function attachmentStatus(status) {
                if (status === EmailAgent.NotDownloaded) {
                    //: Attachment download state - Not Downloaded
                    //% "Not Downloaded"
                    return qsTrId("jolla-email-la-attachment_not_downloaded")
                } else if (status === EmailAgent.Queued) {
                    //: Attachment download state - Queued
                    //% "Queued"
                    return qsTrId("jolla-email-la-attachment_queued")
                } else if (status === EmailAgent.Downloaded) {
                    //: Attachment download state - Downloaded
                    //% "Downloaded"
                    return qsTrId("jolla-email-la-attachment_downloaded")
                } else if (status === EmailAgent.Failed) {
                    //: Attachment download state - Failed
                    //% "Failed"
                    return qsTrId("jolla-email-la-attachment_failed")
                } else if (status === EmailAgent.FailedToSave) {
                    //: Attachment download state - Failed to save file
                    //% "Failed to save file"
                    return qsTrId("jolla-email-la-attachment_failed_save")
                } else if (status === EmailAgent.Canceled) {
                    //: Attachment download state - Download canceled
                    //% "Canceled"
                    return qsTrId("jolla-email-la-attachment_download_canceled")
                } else {
                    return ""
                }
            }
        }

        Label {
            id: sizeLabel
            x: attachmentStatusLabel.crossFade || !attachmentStatusLabel.visible
               ? 0 : attachmentStatusLabel.contentWidth + Theme.paddingMedium
            anchors {
                baseline: attachmentName.baseline
                baselineOffset: root.spacing
            }
            text: statusInfo === EmailAgent.Downloading ? (Format.formatFileSize(downloadedSize, 2)
                                                           + "/" + Format.formatFileSize(size, 2))
                                                        : Format.formatFileSize(size, 2)
            font.pixelSize: attachmentStatusFontSize
            visible: statusInfo === EmailAgent.NotDownloaded || EmailAgent.Downloaded || activated
            color: highlighted ? Theme.highlightColor : Theme.primaryColor
            opacity: attachmentStatusLabel.crossFade && attachmentStatusLabel.visible
                     ? maxStatusOpacity - attachmentStatusLabel.statusOpacity : maxStatusOpacity
        }
    }
}
