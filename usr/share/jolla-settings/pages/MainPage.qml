import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import com.jolla.settings 1.0

Page {
    id: mainPage

    function moveToSection(path) {
        var array = path.split("/")
        if (array.length > 0) {
            var section = array[0]
            if (section.length > 0) {
                for (var i = 0; i < settingsModel.count; ++i) {
                    var object = settingsModel.objectAt(i)
                    if (object && object.name === section) {
                        tabs.moveTo(i, TabViewAction.Immediate)
                        break
                    }
                }
                array.splice(0, 1)
                if (array.length > 0) tabs.moveToSection(array.join("/"))
            }
        }
    }

    function objectForPath(path) {
        return settingsModel.objectForPath(path)
    }

    TabView {
        id: tabs
        currentIndex: 1
        anchors.fill: parent
        signal moveToSection(string path)

        cacheSize: 3
        model: settingsModel
        header: TabBar {
            model: settingsModel
            delegate: TabButton {
                title: object.title
            }
        }

        delegate: SettingsTabItem {
            id: tabItem

            settingsObject: object

            Connections {
                target: tabs
                onMoveToSection: tabItem.moveToSection(path)
            }
        }

        SettingsModel {
            id: settingsModel
            path: []
            depth: 1
        }
    }
}
