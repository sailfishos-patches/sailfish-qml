import QtQuick 2.0

ListModel {
    property var layoutModel
    property bool updating
    property bool emojisEnabled

    property Timer refreshTimer: Timer {
        interval: 1
    }

    function getLayoutIndex(name) {
        for (var i = 0; i < count; ++i) {
            if (get(i).layout === name) {
                return i
            }
        }
        return -1
    }

    function refresh() {
        updating = true
        var enabledLayouts = new Array
        var emojisFound = false

        for (var i = 0; i < layoutModel.count; ++i) {
            var item = layoutModel.get(i)
            if (item.enabled) {
                enabledLayouts.push({"name": item.name, "layout": item.layout})
                if (item.type === "emojis") {
                    emojisFound = true
                }
            }
        }

        for (i = 0; i < enabledLayouts.length && i < count; ++i) {
            set(i, enabledLayouts[i])
        }
        if (enabledLayouts.length > count) {
            for (i = count; i < enabledLayouts.length; ++i) {
                append(enabledLayouts[i])
            }
        } else {
            while (enabledLayouts.length < count) {
                remove(count-1)
            }
        }

        emojisEnabled = emojisFound

        // wait until ComboBox has updated its internal state
        refreshTimer.restart()
    }
}
