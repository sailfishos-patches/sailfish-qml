// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.grilo 0.1

GriloModel {
    id: griloModel

    property string pluginId: "grl-tracker3"
    property alias query: querySource.query
    property alias fetching: querySource.fetching

    signal finished()

    onPluginIdChanged: griloRegistry.safeLoadPluginById()

    function refresh() {
        querySource.safeRefresh()
    }

    source: GriloQuery {
        id: querySource

        property bool canRefresh: applicationActive || cover.status != Cover.Inactive
        property bool shouldRefresh: true
        property Timer delayedRefresh: Timer {
            interval: 3000
            onTriggered: querySource.safeRefresh()
        }

        source: "grl-tracker3-source"
        registry: GriloRegistry {
            id: griloRegistry

            function safeLoadPluginById() {
                if (griloModel.pluginId != "") loadPluginById(griloModel.pluginId)
            }

            Component.onCompleted: safeLoadPluginById()
        }

        function safeRefresh() {
            if (!canRefresh) {
                shouldRefresh = true
                return
            }

            shouldRefresh = false

            if (query && query != "" && available) {
                refresh()
            }
        }

        onQueryChanged: safeRefresh()
        onAvailableChanged: safeRefresh()
        onContentUpdated: delayedRefresh.restart()
        onCanRefreshChanged: if (canRefresh && shouldRefresh) safeRefresh()
        Component.onCompleted: finished.connect(griloModel.finished)
    }
}
