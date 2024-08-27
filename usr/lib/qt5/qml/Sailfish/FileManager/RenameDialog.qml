/****************************************************************************************
** Copyright (c) 2020 Open Mobile Platform LLC.
** Copyright (c) 2021 - 2023 Jolla Ltd.
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

Dialog {
    id: dialog

    property alias oldPath: fileInfo.file

    readonly property string _newPath: fileName.text !== "" && !_hasInvalidCharacters
            ? fileInfo.directoryPath + "/" + fileName.text
            : ""

    readonly property var _regExp: new RegExp("[\/*\?<>\|]+")
    readonly property bool _hasInvalidCharacters: _regExp.test(fileName.text)
    readonly property bool _exists: _newPath !== "" && _newPath !== oldPath && FileEngine.exists(_newPath)

    function _suffixForFileName(fileName) {
        var suffix = FileEngine.extensionForFileName(fileName)
        return suffix !== "" ?  "." + suffix : suffix
    }

    FileInfo {
        id: fileInfo
    }

    DialogHeader {
        id: dialogHeader
        //% "Rename"
        title: qsTrId("filemanager-he-rename")
    }

    TextField {
        id: fileName

        width: parent.width
        anchors.top: dialogHeader.bottom
        label: {
            if (dialog._hasInvalidCharacters) {
               //% "Invalid file name"
               return qsTrId("filemanager-te-invalid_filename")
            } else if (dialog._exists) {
                //% "A file with the same name exists"
                return qsTrId("filemanager-te-filename_exists")
            } else {
               //% "Title"
               return qsTrId("filemanager-la-title")
            }
        }

        placeholderText: qsTrId("filemanager-la-title")
        onFocusChanged: {
            if (focus) {
                var suffix = _suffixForFileName(text)

                select(0, text.length - suffix.length)
            }
        }

        text: fileInfo.fileName
        errorHighlight: dialog._hasInvalidCharacters || dialog._exists

        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.enabled: text !== ""
        EnterKey.onClicked: accept()

        Component.onCompleted: {
            focus = true
        }
    }

    canAccept: _newPath !== "" && !_exists
    onAccepted: {
        if (_newPath !== oldPath) {
            FileEngine.rename(oldPath, _newPath)
        }
    }
}
