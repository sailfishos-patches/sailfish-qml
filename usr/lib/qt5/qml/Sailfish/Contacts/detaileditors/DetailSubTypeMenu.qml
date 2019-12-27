import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

ContextMenu {
    id: root

    property var model
    property int currentIndex: -1
    property int currentSubType: -1
    property bool _updating

    signal subTypeClicked(int type, int subType)

    function _reload() {
        if (!_updating) {
            for (var i = 0; i < repeater.count; ++i) {
                if (repeater.model.get(i).subType === currentSubType) {
                    root._setHighlightedItem(repeater.itemAt(i))
                    root.currentIndex = i
                    return
                }
            }
        }
    }

    onCurrentSubTypeChanged: _reload()

    Repeater {
        id: repeater

        model: root.model

        onCountChanged: root._reload()

        delegate: MenuItem {
            id: menuItem

            text: model.name

            onClicked: {
                if (model.subType !== root.currentSubType) {
                    _updating = true
                    root.currentIndex = model.index
                    _updating = false
                    root.subTypeClicked(model.type, model.subType)
                }
            }

            Component.onCompleted: {
                if (model.subType === root.currentSubType) {
                    root._setHighlightedItem(menuItem)
                    root.currentIndex = model.index
                }
            }
        }
    }
}
