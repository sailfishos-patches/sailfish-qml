import QtQuick 2.0
import Sailfish.Silica 1.0

SettingsMenuItemBase {
    id: menuItem

    property string icon
    property alias iconVisible: image.visible

    visible: icon.length > 0

    Image {
        id: image

        anchors.centerIn: parent
        source: {
            if (menuItem.icon.length > 0) {
                if (menuItem.pressed) {
                  return menuItem.icon + "?" + (Theme.colorScheme == Theme.LightOnDark
                                                ? Theme.highlightColor
                                                : Theme.highlightFromColor(Theme.highlightColor, Theme.LightOnDark))
                } else {
                    return menuItem.icon + "?" + Theme.lightPrimaryColor
                }
            }
            return ""
        }
    }
}
