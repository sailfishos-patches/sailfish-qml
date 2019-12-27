import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0

SettingsToggle {
    onToggled: {
        openMenu()
        _menuItem._setHighlightedItem(_menuItem.itemAt(fontSizeSetting.currentIndex))
    }

    showOnOffLabel: false
    name: fontSizeSetting.currentName
    icon.source: "image://theme/icon-m-font-size"

    menu: Component {
        ContextMenu {
            function itemAt(index) {
                return repeater.itemAt(index)
            }

            Repeater {
                id: repeater

                model: fontSizeSetting.categoryNames
                MenuItem {
                    text: modelData
                    onDelayedClick: fontSizeSetting.update(index)
                }
            }
        }
    }
    FontSizeSetting {
        id: fontSizeSetting
    }
}
