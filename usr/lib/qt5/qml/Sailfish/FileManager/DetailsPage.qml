/****************************************************************************************
** Copyright (c) 2019 Open Mobile Platform LLC.
** Copyright (c) 2023 Jolla Ltd.
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

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.FileManager 1.0
import Nemo.FileManager 1.0

Page {

    property alias fileName: fileNameItem.value
    property alias mimeType: fileTypeItem.value
    property bool isDir
    property date modified
    property double size
    property string path
    property int itemCount

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingMedium

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingSmall

            PageHeader {
                title: isDir ?
                               //% "Directory information"
                               qsTrId("filemanager-he-dir-info")
                               //% "File information"
                             : qsTrId("filemanager-he-file-info")
            }

            DetailItem {
                id: fileNameItem
                //% "Name"
                label: qsTrId("filemanager-he-name")
            }

            DetailItem {
                //% "Size"
                label: qsTrId("filemanager-he-size")
                value: Format.formatFileSize(size)
                visible: !isDir
            }

            DetailItem {
                //% "Contents"
                label: qsTrId("filemanager-he-contents")
                //: Shown when counting number of items a directory (context menu -> details)
                //% "Counting…"
                value: (du.status !== DiskUsage.Idle) ? qsTrId("filemanager-la-counting")
                                                        //% "%n items, totalling %1."
                                                      : qsTrId("filemanager-la-items", itemCount).arg(Format.formatFileSize(size))
                visible: isDir
            }

            DetailItem {
                id: fileTypeItem
                //% "Type"
                label: qsTrId("filemanager-he-type")
            }

            DetailItem {
                //% "Modified"
                label: qsTrId("filemanager-he-modified")
                value: Format.formatDate(modified, Formatter.DateLong)
            }
        }

        VerticalScrollDecorator {}
    }

    DiskUsage { id: du }

    Component.onCompleted: {
        if (isDir) {
            du.calculate(path, function (usage) {
                size = usage[path]
            })

            du.fileCount(path, function(count) {
                itemCount = count
            }, DiskUsage.Files | DiskUsage.Dirs)
        }
    }
}
