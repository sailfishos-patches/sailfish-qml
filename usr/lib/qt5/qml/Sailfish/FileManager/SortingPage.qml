/****************************************************************************************
** Copyright (c) 2016 - 2023 Jolla Ltd.
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
import Nemo.FileManager 1.0

Page {
    id: root

    signal selected(int sortOrder, int sortBy, int directorySort)

    function qsTrIdStrings() {
        //% "Name ascending"
        QT_TRID_NOOP("filemanager-la-name_ascending")
        //% "Name descending"
        QT_TRID_NOOP("filemanager-la-name_descending")
        //% "Size"
        QT_TRID_NOOP("filemanager-la-size")
        //% "Date modified"
        QT_TRID_NOOP("filemanager-la-date_modified")
        //% "Extension"
        QT_TRID_NOOP("filemanager-la-extension")
    }

    SilicaListView {
        anchors.fill: parent
        header: PageHeader {
            //% "Sort"
            title: qsTrId("filemanager-he-sort")
        }
        model: ListModel {
            ListElement {
                sortOrder: Qt.AscendingOrder
                sortBy: FileModel.SortByName
                directorySort: FileModel.SortDirectoriesBeforeFiles
                label: "filemanager-la-name_ascending"
            }
            ListElement {
                sortOrder: Qt.DescendingOrder
                sortBy: FileModel.SortByName
                directorySort: FileModel.SortDirectoriesAfterFiles
                label: "filemanager-la-name_descending"
            }
            ListElement {
                sortOrder: Qt.AscendingOrder
                sortBy: FileModel.SortBySize
                directorySort: FileModel.SortDirectoriesAfterFiles
                label: "filemanager-la-size"
            }
            ListElement {
                sortOrder: Qt.AscendingOrder
                sortBy: FileModel.SortByModified
                directorySort: FileModel.SortDirectoriesBeforeFiles
                label: "filemanager-la-date_modified"
            }
            ListElement {
                sortOrder: Qt.AscendingOrder
                sortBy: FileModel.SortByExtension
                directorySort: FileModel.SortDirectoriesBeforeFiles
                label: "filemanager-la-extension"
            }
        }
        delegate: BackgroundItem {
            onClicked: root.selected(sortBy, sortOrder, directorySort)

            height: Math.max(Theme.itemSizeSmall, sortingLabel.height+2*Theme.paddingMedium)
            Label {
                id: sortingLabel
                anchors.verticalCenter: parent.verticalCenter
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.Wrap
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                text: qsTrId(label)
            }
        }
    }
}
