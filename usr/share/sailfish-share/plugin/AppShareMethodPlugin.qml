/****************************************************************************************
** Copyright (c) 2021 Open Mobile Platform LLC.
** Copyright (c) 2023 Jolla Ltd.
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
import Nemo.DBus 2.0
import Sailfish.Share.AppShare 1.0

Item {
    property var shareAction
    width: parent.width
    height: busy.running ? busy.height : errorLabel.height + Theme.paddingLarge

    InfoLabel {
        id: errorLabel

        property string error
        property int fileCount

        text: {
            // User should not see <undefined>, include it just for completeness
            var name = shareAction ? shareAction.selectedTransferMethodInfo.displayName : "<undefined>"
            if (error === "") {
                return ""
            } else if (error === "org.freedesktop.DBus.Error.InvalidArgs") {
                if (fileCount == 1) {
                    //: The target application (%1) was given one file that it didn't understand
                    //% "The file can not be shared to %1"
                    return qsTrId("sailfishshare-la-error_invalid_args_single_file").arg(name)
                } else {
                    //: The target application (%1) was given multiple files and it didn't understand some of them
                    //% "The files can not be shared to %1"
                    return qsTrId("sailfishshare-la-error_invalid_args_multiple_files").arg(name)
                }
            } else {
                //: Something went wrong while sharing to the target application (%1)
                //% "Failed to share to %1"
                return qsTrId("sailfishshare-la-general_error").arg(name)
            }
        }
    }

    BusyIndicator {
        id: busy

        anchors.horizontalCenter: parent.horizontalCenter
        height: Theme.itemSizeLarge
        running: errorLabel.error === ""
    }

    ShareMethodInfo {
        id: info

        readonly property bool ready: service !== "" && path !== "" && iface !== ""

        methodId: shareAction.selectedTransferMethodInfo.methodId

        onReadyChanged: {
            if (ready) {
                var config = shareAction.toConfiguration()
                errorLabel.fileCount = config["resources"].length
                app.call("share", [config], function() {
                    shareAction.done()
                }, function(error, message) {
                    errorLabel.error = error
                    console.warn("Failed to share:", error, "with message:", message)
                })
            }
        }
    }

    DBusInterface {
        id: app

        service: info.service
        path: info.path
        iface: info.iface
    }
}
