import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.camera 1.0

Loader {
    anchors.fill: parent
    active: counter.active
    asynchronous: true
    sourceComponent: Component {
        Item {
            property string mode: Settings.global.captureMode
            onModeChanged: {
                touchInteractionHint.direction = mode == "image"
                                                    ? TouchInteraction.Up
                                                    : TouchInteraction.Down
                touchInteractionHint.restart()
                counter.increase()
            }

            anchors.fill: parent
            InteractionHintLabel {
                //% "Swipe down to access camera settings"
                text: qsTrId("camera-la-camera_settings_hint")
                anchors.bottom: parent.bottom
                opacity: touchInteractionHint.running ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation { duration: 800 } }
                textColor: Theme.highlightFromColor(Theme.highlightColor, Theme.LightOnDark)
                backgroundColor: Theme.rgba(Theme.highlightDimmerFromColor(Theme.highlightDimmerColor,  Theme.LightOnDark), 0.9)
            }
            TouchInteractionHint {
                id: touchInteractionHint
                loops: 3
                alwaysRunToEnd: true
                distance: Theme.itemSizeMedium
                color: Theme.lightPrimaryColor
            }
        }
    }
    FirstTimeUseCounter {
        id: counter
        limit: 3
        defaultValue: 1 // display hint twice for existing users
        key: "/sailfish/camera/camera_mode_hint_count"
    }
}
