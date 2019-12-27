import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import com.jolla.settings 1.0

Page {
    id: page

    property var selections
    property string originalFilePath

    signal selected(string filePath, string originalFilePath)

    function select(path) {
        selected(path, originalFilePath)
        pageStack.pop()
    }

    ApplicationsGridView {
        id: gridView

        header: Column {
            width: page.width
            spacing: Theme.paddingMedium
            transform: Translate { x:(gridView.width - page.width) / 2 }

            PageHeader {
                //% "Add shortcut"
                title: qsTrId("settings_shortcuts-he-add_shortcut")
            }

            SectionHeader {
                //% "Apps"
                text: qsTrId("settings_shortcuts-he-apps")
            }
        }

        delegate: LauncherGridItem {
            id: appItem

            width: gridView.cellWidth
            height: gridView.cellHeight
            icon: iconId
            text: name
            enabled: selections.indexOf(filePath) == -1
            onClicked: page.select(filePath)
        }
    }
}

