import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

ApplicationWindow {
    id: root

    cover: undefined

    palette {
        colorScheme: Theme.LightOnDark
    }

    BatteryStatus {
        id: batteryStatus

        onFullChanged: {
            if (actdeadApplication.verboseMode) {
                console.log("full:", full)
            }
            if (full) {
                actdeadApplication.requestMceDisplayOn("batteryfull_changed", 3000)
            }
        }
        onChargingChanged: {
            if (actdeadApplication.verboseMode) {
                console.log("charging:", charging)
            }
            actdeadApplication.requestMceDisplayOn("charging_changed", 3000)
        }
    }

    Connections {
        target: actdeadApplication
        onUsbModeChanged: {
            if (actdeadApplication.verboseMode) {
                console.log("usb-mode:", actdeadApplication.usbMode)
            }
            // On cable connect the usb-mode notification is received
            // a fraction of second before charging related property
            // notifications start to trickle in -> using usb-mode change
            // to trigger display wakeup increases the chances that the
            // charging related animations are actually shown on screen
            if (actdeadApplication.usbMode === "USB connected" ||
                actdeadApplication.usbMode === "USB disconnected") {
                actdeadApplication.requestMceDisplayOn("usbconnection_changed", 3000)
            }
        }
    }

    Rectangle {
        color: "black"
        anchors.fill: parent
    }
    Item {
        anchors.fill: parent
        opacity: !actdeadApplication.splashScreenVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 1000 } }
        Image {
            id: background
            anchors.centerIn: parent
            source: "image://theme/graphic-os-state-background"
            opacity: batteryStatus.error ? 0.2
                                         : batteryStatus.full ? 1.0 : 0.3
            Behavior on opacity { FadeAnimation {}}
        }
        Image {
            anchors.centerIn: parent
            source: "image://theme/graphic-os-state-attention"
            opacity: batteryStatus.error ? 0.1 : 0.0
            Behavior on opacity { FadeAnimation {}}
        }
        Icon {
            id: powerIcon
            anchors.centerIn: parent
            source: "image://theme/icon-os-state-power"
            color: batteryStatus.full && !batteryStatus.error ? "black" : "white"
            Behavior on opacity { FadeAnimation {}}
        }
        Item {
            id: usbWireParent
            clip: true
            width: parent.width
            anchors {
                bottom: background.top
                horizontalCenter: background.horizontalCenter
                top: parent.top
            }

            SequentialAnimation {
                alwaysRunToEnd: true
                loops: Animation.Infinite
                running: batteryStatus.full || batteryStatus.error
                NumberAnimation {
                    target: usbWireParent
                    from: 1.0
                    to: 0.4
                    property: "opacity"
                    duration: 1000
                }
                NumberAnimation {
                    target: usbWireParent
                    from: 0.4
                    to: 1.0
                    property: "opacity"
                    duration: 1000
                }
            }

            Image {
                id: usbWire

                anchors {
                    bottom: usbBin.top
                    horizontalCenter: parent.horizontalCenter
                }
                opacity: 1.0
                source: "image://theme/graphic-os-usb"
            }
            Image {
                id: usbBin
                y: parent.height - Theme.itemSizeMedium
                anchors.horizontalCenter: parent.horizontalCenter
                fillMode: Image.PreserveAspectCrop
                source: "image://theme/graphic-os-usb-pin"
            }
        }
        Text {
            id: percentage
            anchors.centerIn: background
            text: batteryStatus.chargePercentage
            color: batteryStatus.full ? "black"
                                      : (batteryStatus.empty ? "red" : Theme.lightPrimaryColor)
            font {
                family: Theme.fontFamilyHeading
                pixelSize: Theme.fontSizeExtraLarge + Theme.fontSizeHuge
            }
            opacity: 0.0
        }
        Text {
            anchors {
                top: percentage.baseline
                bottom: background.bottom
                horizontalCenter: percentage.horizontalCenter
            }
            verticalAlignment: Text.AlignVCenter
            text: "%"
            opacity: 0.4 * percentage.opacity
            color: percentage.color
            font.pixelSize: Theme.fontSizeExtraLarge
        }

        states: State {
            name: "charging"
            when: batteryStatus.charging
            PropertyChanges {
                target: usbWire
                opacity: batteryStatus.full ? 1.0 : 0.3
            }
            PropertyChanges {
                target: usbBin
                opacity: batteryStatus.full ? 1.0 : 0.3
                y: usbBin.parent.height
            }
            PropertyChanges {
                target: percentage
                opacity: batteryStatus.error ? 0.0 : 1.0
            }
            PropertyChanges {
                target: powerIcon
                opacity: batteryStatus.error ? 1.0 : 0.05
            }
        }
        transitions: Transition {
            from: ""
            to: "charging"
            reversible: true
            SequentialAnimation {
                PropertyAnimation {
                    duration: 300
                    properties: "y"
                    easing.type: Easing.InOutQuad
                }
                PropertyAnimation {
                    duration: 300
                    properties: "opacity"
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
    ShutDownItem {
        mode: ShutdownMode.Reboot
        opacity: actdeadApplication.splashScreenVisible ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 1000 } }
    }

    property Item _chargerTestItem
    Component.onCompleted: {
        if (actdeadApplication.debugMode) {
            var component = Qt.createComponent("ChargerTestItem.qml")
            if (component.status === Component.Ready) {
                _chargerTestItem = component.createObject(root)
            } else {
                console.log(component.errorString())
            }
        }
    }
}
