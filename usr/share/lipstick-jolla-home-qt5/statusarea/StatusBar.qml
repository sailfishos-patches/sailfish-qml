import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

Item {
    id: statusBar

    property real baseY: Theme.paddingMedium + Theme.paddingSmall

    property alias updatesEnabled: statusArea.updatesEnabled
    property alias recentlyOnDisplay: statusArea.recentlyOnDisplay
    property alias lockscreenMode: statusArea.lockscreenMode
    property alias iconSuffix: statusArea.iconSuffix
    property alias color: statusArea.color
    property alias backgroundVisible: background.visible

    width: parent.width
    height: baseY + statusArea.height

    SilicaPrivate.OverlayGradient {
        id: background
        visible: false
        anchors {
            fill: parent
            bottomMargin: -2 * Theme.paddingLarge
        }
        opacity: 1.0 - Math.abs(statusBar.y/Theme.paddingMedium)
    }


    MouseArea {
        property Item window: Lipstick.compositor.topmostWindow
        property bool partnerOnTop: window && window.windowType == WindowType.PartnerSpace

        enabled: !statusAreaContainer.clip && !partnerOnTop
        anchors {
            fill: parent
            bottomMargin: -Theme.paddingLarge
        }
        onClicked: Lipstick.compositor.topMenuHinting = true
    }

    Item {
        id: statusAreaContainer
        height: parent.height
        width: parent.width
        clip: Lipstick.compositor.statusBarPushDownY > 0
        StatusArea {
            id: statusArea
            y: baseY + Lipstick.compositor.statusBarPushDownY
        }
    }
}
