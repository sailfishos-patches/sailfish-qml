/****************************************************************************************
**
** Copyright (c) 2013 - 2021 Jolla Ltd.
** Copyright (c) 2021 Open Mobile Platform LLC
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.TransferEngine 1.0

SilicaFlickable {
    id: root

    property var shareAction
    property bool supportsUrlType
    property alias postButtonText: postButton.text

    width: parent.width
    height: contentHeight
    contentHeight: contentColumn.height

    Component.onCompleted: {
        sailfishTransfer.loadConfiguration(shareAction.toConfiguration())
        statusTextField.forceActiveFocus()
        statusTextField.cursorPosition = statusTextField.text.length
    }

    SailfishTransfer {
        id: sailfishTransfer
    }

    Column {
        id: contentColumn

        width: parent.width

        TextArea {
            id: linkTextField

            width: parent.width
            //% "Link"
            label: qsTrId("sailfishshare-la-link")
            placeholderText: label
            visible: supportsUrlType && sailfishTransfer.content.type === "text/x-url"
            text: sailfishTransfer.content.status || ""
        }

        TextArea {
            id: statusTextField

            width: parent.width
            //% "Status update"
            label: qsTrId("sailfishshare-la-status_update")
            placeholderText: label
            text: {
                var s = sailfishTransfer.content.linkTitle || ""
                if (linkTextField.visible) {
                    // the status is a url and is already shown in link field, don't repeat it here
                    return s
                }
                var status = sailfishTransfer.content.status || ""
                if (s.length > 0) {
                    s += ": "
                }
                return s + status
            }
        }

        SystemDialogIconButton {
            id: postButton

            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width / 2
            iconSource: "image://theme/icon-m-share"
            bottomPadding: Theme.paddingLarge
            _showPress: false

            //: Post a social network account status update
            //% "Post"
            text: qsTrId("sailfishshare-la-post_status")

            onClicked: {
                sailfishTransfer.userData = {
                    "accountId": sailfishTransfer.transferMethodInfo.accountId,
                    "status": statusTextField.text
                }
                if (supportsUrlType) {
                    sailfishTransfer.userData.link = linkTextField.text
                }
                sailfishTransfer.mimeType = (supportsUrlType && sailfishTransfer.content.type === "text/x-url")
                        ? "text/x-url"
                        : "text/plain"
                sailfishTransfer.start()
                root.shareAction.done()
            }
        }
    }
}
