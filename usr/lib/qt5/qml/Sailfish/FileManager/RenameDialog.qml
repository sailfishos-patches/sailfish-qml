/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */
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
