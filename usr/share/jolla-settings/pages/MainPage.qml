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

        header: TabBar {
            model: tabBarModel
        }

        ListModel {
            id: tabBarModel
        }

        SettingsModel {
            id: settingsModel
            path: []
            depth: 1
            Component.onCompleted: {
                var array = []
                for (var i = 0; i < count; i++) {
                    tabBarModel.append({"title": settingsModel.objectAt(i).title})
                    var component = Qt.createQmlObject("
import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0

Component {
    SettingsTabItem {
        id: tabItem

        settingsObject: settingsModel.objectAt(" + i + ")

        Connections {
            target: tabs
            onMoveToSection: tabItem.moveToSection(path)
        }
    }
}", tabs, "tabComponent")
                    array.push(component)
                }

                // TODO: JB#47931 Should be possile to use
                // QAbstractListModel directly on TabsView.model
                tabs.model = array
            }
        }
    }
}
