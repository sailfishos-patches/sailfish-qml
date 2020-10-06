/*
 * Copyright (c) 2018 – 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import org.nemomobile.thumbnailer 1.0

Row {
    id: root

    property var emailMessage
    property AttachmentListModel attachmentsModel

    readonly property int _maximumVisibleAttachments: {
        if (Screen.sizeCategory < Screen.Large) {
            return 2
        } else if (portrait) {
            return 3
        } else {
            return 4
        }
    }

    height: Theme.itemSizeExtraSmall

    Repeater {
        model: emailMessage && emailMessage.numberOfAttachments > 0 &&
               emailMessage.numberOfAttachments <= _maximumVisibleAttachments
               ? attachmentsModel
               : null
        delegate: AttachmentDelegate {
            id: attachmentItem

            leftMargin: attachmentItem.Positioner.isFirstItem
                        ? Theme.horizontalPageMargin
                        : Theme.paddingMedium
            rightMargin: attachmentItem.Positioner.isLastItem
                        ? Theme.horizontalPageMargin
                        : Theme.paddingMedium

            width: ((root.width - (2 * (Theme.horizontalPageMargin - Theme.paddingMedium))) / emailMessage.numberOfAttachments)
                    + (leftMargin - Theme.paddingMedium)
                    + (rightMargin - Theme.paddingMedium)

            contentHeight: Theme.itemSizeExtraSmall

            attachmentNameFontSize: Theme.fontSizeExtraSmall
            attachmentStatusFontSize: Theme.fontSizeExtraSmall
        }
    }

    BackgroundItem {
        id: attachmentsLink
        visible: emailMessage && emailMessage.numberOfAttachments > root._maximumVisibleAttachments
        contentHeight: Theme.itemSizeExtraSmall

        onClicked: {
            pageStack.animatorPush("AttachmentListPage.qml", {
                                       messageId: emailMessage.messageId,
                                       attachmentsModel: root.attachmentsModel
                                   })
        }

        Label {
            //: Number of email attachments (only used when number of attachments greater than 2)
            //% "%n attachments"
            text: qsTrId("jolla-email-la-attachments_summary", emailMessage ? emailMessage.numberOfAttachments : 0)
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
                margins: Theme.horizontalPageMargin
            }
        }
    }
}
