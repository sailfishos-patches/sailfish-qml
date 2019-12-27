/*
 * Copyright (c) 2018 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1

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
    Repeater {
        model: emailMessage && emailMessage.numberOfAttachments > 0 &&
               emailMessage.numberOfAttachments <= _maximumVisibleAttachments
               ? attachmentsModel
               : null
        delegate: AttachmentDelegate {
            // Two delegates
            width: root.width / emailMessage.numberOfAttachments
            leftMargin: Positioner.isFirstItem ? Theme.horizontalPageMargin : Theme.paddingMedium
            rightMargin: Positioner.isLastItem ? Theme.horizontalPageMargin : Theme.paddingMedium
            iconSize: Theme.iconSizeMedium
            attachmentNameFontSize: Theme.fontSizeExtraSmall
            attachmentStatusFontSize: Theme.fontSizeTiny
            contentHeight: Theme.itemSizeSmall
            spacing: Theme.paddingLarge
        }
    }

    BackgroundItem {
        id: attachmentsLink
        visible: emailMessage && emailMessage.numberOfAttachments > root._maximumVisibleAttachments
        contentHeight: Theme.itemSizeSmall

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
            color: attachmentsLink.highlighted ? Theme.highlightColor : Theme.primaryColor
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                right: parent.right
                margins: Theme.horizontalPageMargin
            }
        }
    }
}
