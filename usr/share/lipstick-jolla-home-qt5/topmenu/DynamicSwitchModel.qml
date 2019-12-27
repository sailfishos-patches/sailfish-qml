import QtQuick 2.2
import com.jolla.settings 1.0

ListModel {
    id: dynamicSwitchModel

    property bool settingsLoaded
    property var userDefinedSwiches
    default property alias statusObjects: container.resources

    property Item __props: Item {
        id: container
    }

    property SettingsModel _settings: SettingsModel {
        id: settings

        onModelReset: {
            dynamicSwitchModel.settingsLoaded = true
            dynamicSwitchModel.updateAll()
        }
    }

    function updateAll() {
        if (!settingsLoaded)
            return

        for (var i = 0; i < statusObjects.length; ++i) {
            dynamicSwitchModel.updateItem(statusObjects[i])
        }
    }

    function updateItem(statusObject) {
        if (!settingsLoaded)
            return

        var path = statusObject.path
        var enabled = statusObject.enabled
        var userAdded = userDefinedSwiches.isFavorite(path)
        var i = 0
        var modelObject = null

        if (enabled && !userAdded) {
            var found = false
            for (i = 0; i < dynamicSwitchModel.count; ++i) {
                modelObject = dynamicSwitchModel.get(i)
                if (modelObject.object.location().join("/") == path) {
                    found = true
                }
            }

            var treeItem = settings.objectForPath(path)
            if (!found && treeItem) {
                dynamicSwitchModel.append({
                                                "object": treeItem,
                                                "statusObject": statusObject
                                            })
            }
        } else {
            for (i = 0; i < dynamicSwitchModel.count; ++i) {
                modelObject = dynamicSwitchModel.get(i)
                if (modelObject.object.location().join("/") == path) {
                    dynamicSwitchModel.remove(i)
                }
            }
        }
    }
}
