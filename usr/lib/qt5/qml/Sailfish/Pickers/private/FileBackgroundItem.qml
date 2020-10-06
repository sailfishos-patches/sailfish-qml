/****************************************************************************
**
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.FileManager 1.0

BackgroundItem {
    id: root

    property string baseName
    property string extension
    property alias mimeType: fileItem.mimeType
    property alias size: fileItem.size
    property alias created: fileItem.created
    property alias modified: fileItem.modified
    property alias textFormat: fileItem.textFormat

    readonly property string iconSource: fileItem.icon.source
    property alias isDir: fileItem.isDir
    readonly property bool isParentDirectory: baseName == '..' && extension == ''

    property bool selected

    width: ListView.view.width
    height: fileItem.height
    highlighted: down || selected

    Binding {
        when: isParentDirectory
        target: fileItem.icon
        property: "source"
        value: "image://theme/icon-m-page-up"
    }

    FileItem {
        id: fileItem

        fileName: root.isParentDirectory
                    //% "Parent folder"
                  ? qsTrId("components_pickers-la-parent_folder")
                  : root.baseName + root.extension
    }

}
