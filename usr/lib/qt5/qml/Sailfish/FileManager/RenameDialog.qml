/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */
import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.FileManager 1.0

Dialog {
    property string oldPath
    property string oldName

    property bool _sameName: true
    readonly property var _regExp: new RegExp("[\/*\?<>\|]+")
    // FIXME : JB#50567 here that use file name suffix from FileInfo instead.
    property string _suffix: fileName.text.replace(_baseName(fileName.text), "")
    property int _selectionLength: fileName.text.length - _suffix.length
    // FIXME : JB#50567 here that use basePath from FileInfo instead.
    property string _directory

    function _renameFile(fileName) {
        var newPath = oldPath.replace(oldName, fileName)
        var exist = FileEngine.exists(newPath)

        var counter = 0
        while (exist) {
            counter++
            var incrementedFileName = _baseName(fileName) + "(%1)".arg(counter) + _suffix

            if (incrementedFileName === oldName)
                return

            var path = _directory + incrementedFileName
            newPath = path
            exist = FileEngine.exists(newPath)
        }
        FileEngine.rename(oldPath, newPath)
    }

    // FIXME : JB#50567 here that use baseName from FileInfo instead.
    function _baseName(fileName) {
        var baseName = fileName
        if (baseName.lastIndexOf(".") !== -1)
            baseName = baseName.substring(0, baseName.lastIndexOf("."));
        return baseName;
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
        label: errorHighlight
               //% "Invalid file name"
               ? qsTrId("filemanager-te-invalid_filename")
               //% "Title"
               : qsTrId("filemanager-la-title")

        placeholderText: qsTrId("filemanager-la-title")
        onFocusChanged: if (focus) select(0, _selectionLength)

        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.enabled: text !== ""
        EnterKey.onClicked: accept()

        Component.onCompleted: {
            text = oldName

            focus = true

            textChanged.connect(function () {
                errorHighlight = _regExp.test(text)
                _sameName = oldName === text
            })

            _directory = oldPath.replace(oldName, "")
        }
    }

    canAccept: !fileName.errorHighlight && fileName.text !== ""
    onAccepted: if (!_sameName) _renameFile(fileName.text)
}
