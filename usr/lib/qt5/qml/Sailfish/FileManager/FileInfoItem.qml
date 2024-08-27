/****************************************************************************************
** Copyright (c) 2019 - 2023 Jolla Ltd.
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

    property alias icon: mimeIcon
    property alias fileName: fileNameLabel.text
    property string mimeType: fileInfo ? fileInfo.mimeType : ""
    property int fileSize: fileInfo ? fileInfo.size : -1
    property real leftMargin: Theme.horizontalPageMargin
    property real rightMargin: Theme.horizontalPageMargin

    property var fileInfo

    width: parent.width
    leftPadding: leftMargin
    rightPadding: rightMargin
    spacing: Theme.paddingMedium

    Image {
        id: mimeIcon

        y: parent.height/2 - height/2
        source: Theme.iconForMimeType(root.mimeType)
    }

    Column {
        y: parent.height/2 - height/2
        width: parent.width - root.leftMargin - root.rightMargin - mimeIcon.width

        Label {
            id: fileNameLabel

            width: parent.width
            truncationMode: TruncationMode.Fade
            color: Theme.highlightColor
            text: root.fileInfo ? root.fileInfo.fileName : ""
        }

        Label {
            text: root.fileSize >= 0 ? Format.formatFileSize(root.fileSize) : ""
            visible: text.length > 0
            width: parent.width
            truncationMode: TruncationMode.Fade
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeSmall
        }
    }
}
