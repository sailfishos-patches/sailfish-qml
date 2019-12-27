import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

ContextMenu {
    id: root

    property int currentIndex: -1
    property int currentLabel: -1
    property bool _updating

    signal labelClicked(int label)

    onCurrentLabelChanged: {
        if (!_updating) {
            for (var i = 0; i < repeater.count; ++i) {
                if (repeater.model[i] === currentLabel) {
                    root._setHighlightedItem(repeater.itemAt(i))
                    root.currentIndex = i
                    return
                }
            }
        }
    }

    Repeater {
        id: repeater

        model: ContactsUtil.labels

        delegate: MenuItem {
            id: menuItem

            text: (modelData === Person.NoLabel)
                  ? ContactsUtil.getNoLabelText()
                  : ContactsUtil.getNameForLabelledDetail(undefined, modelData)

            onClicked: {
                if (modelData !== root.currentLabel) {
                    _updating = true
                    root.currentIndex = model.index
                    _updating = false
                    root.labelClicked(modelData)
                }
            }

            Component.onCompleted: {
                if (modelData === root.currentLabel) {
                    root._setHighlightedItem(menuItem)
                    root.currentIndex = model.index
                }
            }
        }
    }
}
