import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import org.nemomobile.lipstick 0.1
import org.nemomobile.devicelock 1.0
import com.jolla.lipstick 0.1

ApplicationWindow {
    id: applicationWindow

    function powerButtonTriggered() {
        if (!Lipstick.compositor.systemGesturesDisabled && DeviceLock.state <= DeviceLock.Locked) {
            Lipstick.compositor.powerKeyPressed = true
            Lipstick.compositor.topMenuLayer.show()
        } else {
            dsmeDbus.call("req_shutdown", [])
        }
    }

    cover: undefined

    allowedOrientations: Lipstick.compositor.topmostWindowOrientation

    initialPage: Component {
        Page {
            id: page

            allowedOrientations: Orientation.All

            TouchBlocker {
                anchors.fill: parent
            }

            MouseArea {
                objectName: "TopMenuWindow"
                anchors.fill: parent
                onClicked: Lipstick.compositor.topMenuLayer.hide()
            }

            TopMenu {
                id: menu

                height: Math.min(implicitHeight, page.height)
                anchors.horizontalCenter: parent.horizontalCenter
                y: page.orientationTransitionRunning
                   ? 0
                   : height - Math.max(0, Lipstick.compositor.topMenuLayer.absoluteExposure)

                onShutdown: dsmeDbus.call("req_shutdown", [])
                onReboot: dsmeDbus.call("req_reboot", [])

                Component.onCompleted: {
                    Lipstick.compositor.topMenuLayer.topMenu = menu
                }
            }

            Image {
                y: menu.expanded && menu.contentHeight >= page.height + height && menu.atYEnd ? page.height - height :
                                                                                                menu.exposedArea.height - height
                anchors.horizontalCenter: parent.horizontalCenter
                source: "image://theme/graphic-edge-swipe-handle-bottom"
                rotation: 180
            }

            Binding {
                target: Lipstick.compositor.topMenuLayer
                property: "margin"
                value: page.height - menu.height
            }
        }
    }

    DBusInterface {
        id: dsmeDbus
        bus: DBus.SystemBus
        service: "com.nokia.dsme"
        path: "/com/nokia/dsme/request"
        iface: "com.nokia.dsme.request"
    }
}
