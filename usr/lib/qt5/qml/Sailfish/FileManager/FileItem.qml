/****************************************************************************************
** Copyright (c) 2018 - 2023 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC
**
** All rights reserved.
**
** This file is part of Sailfish FileManager components package.
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

Row {
    id: root

    property string fileName
    property string mimeType
    property double size
    property bool isDir
    property var created
    property var modified
    property bool compressed

    readonly property alias icon: icon
    property alias textFormat: nameLabel.textFormat

    width: parent.width
    height: Theme.itemSizeMedium
    spacing: Theme.paddingLarge

    Rectangle {
        width: height
        height: parent.height
        gradient: Gradient {
            // Abusing gradient for inactive mimeTypes
            GradientStop { position: 0.0; color: Theme.rgba(Theme.primaryColor, 0.1) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        HighlightImage {
            id: icon

            anchors.centerIn: parent
            source: root.isDir
                    ? "image://theme/icon-m-file-folder"
                    : Theme.iconForMimeType(root.mimeType)
        }

        Image {
            anchors {
                top: parent.top
                right: parent.right
            }
            visible: compressed

            source: {
                var iconSource = "image://theme/icon-m-file-compressed"
                return iconSource + (highlighted ? "?" + Theme.highlightColor : "")
            }
        }
    }

    Column {
        width: parent.width - parent.height - parent.spacing - Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter

        Label {
            id: nameLabel
            text: root.fileName
            width: parent.width
            truncationMode: TruncationMode.Fade
        }

        Label {
            property string dateString: Format.formatDate(root.modified || root.created, Formatter.DateLong)
            text: root.isDir ? dateString
                                //: Shows size and modification/created date, e.g. "15.5MB, 02/03/2016"
                                //% "%1, %2"
                              : qsTrId("filemanager-la-file_details").arg(Format.formatFileSize(root.size)).arg(dateString)
            width: parent.width
            truncationMode: TruncationMode.Fade
            font.pixelSize: Theme.fontSizeExtraSmall
            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            textFormat: nameLabel.textFormat
        }
    }
}
