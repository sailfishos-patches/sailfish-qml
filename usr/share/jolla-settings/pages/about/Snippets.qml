import QtQuick 2.2
import Sailfish.Silica 1.0
import Qt.labs.folderlistmodel 2.1

Repeater {
    property alias folder: folderModel.folder

    model: FolderListModel {
        id: folderModel

        folder: "/usr/share/jolla-settings/pages/about/snippets"
        showDirs: false
        nameFilters: ["*.qml", "*.txt"]
        sortField: FolderListModel.Name
    }

    delegate: Loader {
        // This makes the file path property available for the source component:
        property var path: model.filePath

        width: parent ? parent.width : 0

        onPathChanged: {
            source = ""
            sourceComponent = undefined
            if (path) {
                var extension = path.substr(-4, 4)
                if (extension === ".qml") {
                    source = path
                } else if (extension === ".txt") {
                    sourceComponent = textSnippet
                }
            }
        }
    }
}
