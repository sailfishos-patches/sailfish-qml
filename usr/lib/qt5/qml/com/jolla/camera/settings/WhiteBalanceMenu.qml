import QtQuick 2.2
import Sailfish.Silica 1.0
import com.jolla.camera 1.0

ExpandingMenu {
    id: menu
    model: CameraConfigs.supportedWhiteBalanceModes
    delegate: ExpandingMenuItem {
        persistentHighlight: true
        settings: Settings.global
        property: "whiteBalance"
        value: modelData
        icon: Settings.whiteBalanceIcon(modelData)
        visible: icon.length > 0
        Label {
            anchors.verticalCenter: parent.verticalCenter
            x: alignment === Qt.AlignLeft ? parent.width + Theme.paddingLarge : -width - Theme.paddingLarge
            color: Theme.colorScheme == Theme.LightOnDark
                   ? Theme.highlightColor : Theme.highlightFromColor(Theme.highlightColor, Theme.LightOnDark)
            text: Settings.whiteBalanceText(modelData)
            font.bold: true
            opacity: selected && open ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {} }
        }
    }
}
