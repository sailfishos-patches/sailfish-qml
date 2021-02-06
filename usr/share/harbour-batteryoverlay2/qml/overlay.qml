import QtQuick 2.1
import Sailfish.Silica 1.0
import QtSensors 5.0
import Nemo.Configuration 1.0
;import org.nemomobile.systemsettings 1.0

Item {
    id: root

    width: Screen.width
    height: Screen.height
    visible: battery.chargePercentage <= configuration.threshold

    property int statusBarPushDownY: 0

    Connections {
        target: viewHelper
        onApplicationRemoval: {
            removalOverlay.opacity = 1.0
        }
    }

    Item {
        id: rotationItem

        anchors.centerIn: root
        width: orientationSensor.angle % 180 == 0 ? Screen.width : Screen.height
        height: orientationSensor.angle % 180 == 0 ? Screen.height : Screen.width
        rotation: orientationSensor.angle

        opacity: configuration.opacityPercentage / 100.0

        property bool inverted: !configuration.followOrientation && (configuration.fixedOrientation == 1
                                                                     || configuration.fixedOrientation == 2)

        Rectangle {
            id: chargedBar
            x: rotationItem.inverted ? unchargedBar.width : 0
            height: configuration.lineHeight
            width: rotationItem.width * battery.chargePercentage / 100
            gradient: Gradient {
                GradientStop { position: 0.0; color: configuration.chargedColor }
                GradientStop { position: 1.0; color: configuration.gradientOpacity ? "transparent" : configuration.chargedColor }
            }
        }

        Rectangle {
            id: unchargedBar
            x: rotationItem.inverted ? 0 : chargedBar.width
            width: rotationItem.width - chargedBar.width
            height: configuration.lineHeight
            gradient: Gradient {
                GradientStop { position: 0.0; color: configuration.unchargedColor }
                GradientStop { position: 1.0; color: configuration.gradientOpacity ? "transparent" : configuration.unchargedColor }
            }
        }
    }

    MouseArea {
        id: removalOverlay

        anchors.fill: parent
        enabled: opacity == 1.0
        onEnabledChanged: {
            if (enabled)
                viewHelper.setMouseRegion(0, 0, Screen.width, Screen.height)
        }
        opacity: 0.0
        Behavior on opacity {
            SmoothedAnimation { duration: 1000 }
        }

        onClicked: {
            viewHelper.removeService()
            Qt.quit()
        }

        MouseArea {
            anchors {
                fill: removalContent
                margins: -Theme.paddingLarge
            }
            enabled: removalOverlay.enabled

            Rectangle {
                anchors.fill: parent
                color: Theme.highlightDimmerColor
            }
        }

        Column {
            id: removalContent

            anchors {
                centerIn: parent
            }
            width: Screen.width - Theme.paddingLarge * 2

            spacing: Theme.paddingLarge

            Row {
                spacing: Theme.paddingLarge
                height: iconContent.height
                anchors.horizontalCenter: parent.horizontalCenter

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Application removal"
                }

                Item {
                    id: iconContent

                    width: appIcon.sourceSize.width
                    height: appIcon.sourceSize.height

                    Image {
                        id: appIcon
                        anchors.centerIn: parent
                        source: "/usr/share/icons/hicolor/86x86/apps/harbour-batteryoverlay2.png"
                    }

                    Label {
                        id: sadFace
                        anchors.centerIn: parent
                        text: ":("
                        font.bold: true
                        opacity: 0.0
                    }

                    Timer {
                        interval: 3000
                        running: removalOverlay.enabled
                        repeat: true
                        onTriggered: {
                            if (iconContent.rotation == 0) {
                                sadAnimation.start()
                            }
                            else {
                                iconAnimation.start()
                            }
                        }
                    }

                    ParallelAnimation {
                        id: sadAnimation
                        NumberAnimation {
                            target: iconContent
                            property: "rotation"
                            from: 0
                            to: 360
                            duration: 1000
                        }
                        NumberAnimation {
                            target: appIcon
                            property: "opacity"
                            from: 1.0
                            to: 0.0
                            duration: 1000
                        }
                        NumberAnimation {
                            target: sadFace
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: 1000
                        }
                    }

                    ParallelAnimation {
                        id: iconAnimation
                        NumberAnimation {
                            target: iconContent
                            property: "rotation"
                            from: 360
                            to: 0
                            duration: 1000
                        }
                        NumberAnimation {
                            target: appIcon
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: 1000
                        }
                        NumberAnimation {
                            target: sadFace
                            property: "opacity"
                            from: 1.0
                            to: 0.0
                            duration: 1000
                        }
                    }
                }
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter

                text: "I'm sorry You unsatisfied with my application. Please tell me why, and I will try to do my best to improve it."
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Leave comment in Jolla Store"
                enabled: removalOverlay.enabled
                onClicked: {
                    viewHelper.removeService()
                    viewHelper.openStore()
                    Qt.quit()
                }
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No, thanks"
                enabled: removalOverlay.enabled
                onClicked: {
                    viewHelper.removeService()
                    Qt.quit()
                }
            }
        }
    }

    OrientationSensor {
        id: orientationSensor
        active: configuration.followOrientation
        property var hack: if (reading && reading.orientation) _getOrientation(reading.orientation)
        property int sensorAngle: 0
        property int angle: active
                              ? (configuration.orientationLock == "dynamic" || configuration.orientationLock == ""
                                 ? sensorAngle
                                 : (configuration.orientationLock == "portrait" ? 0 : 90))
                              : (configuration.fixedOrientation * 90)
        function _getOrientation(value) {
            switch (value) {
            case 1:
                sensorAngle = 0
                break
            case 2:
                sensorAngle = 180
                break
            case 3:
                sensorAngle = -90
                break
            case 4:
                sensorAngle = 90
                break
            default:
                return false
            }
            return true
        }
    }

    QtObject {
        id: battery
        property int chargePercentage: batteryStatus.chargePercentage
        property bool isCharging: batteryStatus.chargerStatus === BatteryStatus.Connected
    }

    BatteryStatus {
        id: batteryStatus
    }

    ConfigurationGroup {
        id: internal
        path: "/apps/harbour-battery-overlay"
        property bool followOrientation: false
        property int lineHeight: 5
        property int opacityPercentage: 50
        property string normalChargedColor: "green"
        property string normalUnchangedColor: "red"
        property string chargingChargedColor: "cyan"
        property string chargingUnchargedColor: "blue"
        property bool useSystemColors: false
        property bool displayChargingStatus: false
        property int fixedOrientation: 0
        property bool gradientOpacity: true
        property int threshold: 100
    }

    ConfigurationValue {
        id: orientationConf
        key: "/lipstick/orientationLock"
        defaultValue: "dynamic"
    }

    QtObject {
        id: configuration

        property bool followOrientation: internal ? internal.followOrientation : false
        property int lineHeight: internal ? internal.lineHeight : 5
        property int opacityPercentage: internal ? internal.opacityPercentage : 50
        property string normalChargedColor: internal ? internal.normalChargedColor : "green"
        property string normalUnchangedColor: internal ? internal.normalUnchangedColor : "red"
        property string chargingChargedColor: internal ? internal.chargingChargedColor : "cyan"
        property string chargingUnchargedColor: internal ? internal.chargingUnchargedColor : "blue"
        property bool useSystemColors: internal ? internal.useSystemColors : false
        property bool displayChargingStatus: internal ? internal.displayChargingStatus : false
        property int fixedOrientation: internal ? internal.fixedOrientation : 0
        property bool gradientOpacity: internal ? internal.gradientOpacity : true
        property int threshold: internal ? internal.threshold : 100

        property string systemChargedColor: displayChargingStatus && battery.isCharging
                                            ? Theme.highlightColor
                                            : Theme.highlightBackgroundColor
        property string systemUnchargedColor: displayChargingStatus && battery.isCharging
                                                     ? Theme.secondaryHighlightColor
                                                     : Theme.highlightDimmerColor
        property string settingsChargedColor: displayChargingStatus && battery.isCharging
                                      ? chargingChargedColor
                                      : normalChargedColor
        property string settingsUnchargedColor: displayChargingStatus && battery.isCharging
                                        ? chargingUnchargedColor
                                        : normalUnchangedColor
        property string chargedColor: useSystemColors ? systemChargedColor : settingsChargedColor
        property string unchargedColor: useSystemColors ? systemUnchargedColor : settingsUnchargedColor

        property string orientationLock: orientationConf ? orientationConf.value : "dynamic"
    }
}
