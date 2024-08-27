/****************************************************************************************
** Copyright (c) 2013 - 2023 Jolla Ltd.
** Copyright (c) 2021 Open Mobile Platform LLC
**
** All rights reserved.
**
** This file is part of Sailfish Transfer Engine component package.
**
** You may use this file under the terms of BSD license as follows:
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**
** 1. Redistributions of source code must retain the above copyright notice, this
**    list of conditions and the following disclaimer.
**
** 2. Redistributions in binary form must reproduce the above copyright notice,
**    this list of conditions and the following disclaimer in the documentation
**    and/or other materials provided with the distribution.
**
** 3. Neither the name of the copyright holder nor the names of its
**    contributors may be used to endorse or promote products derived from
**    this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
** AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
** FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
** DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
** SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
** CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
** OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
