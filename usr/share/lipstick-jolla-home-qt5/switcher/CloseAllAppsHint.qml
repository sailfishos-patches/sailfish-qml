import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    anchors.fill: parent
    active: counter.active && housekeeping
    onActiveChanged: if (active) active = true // remove binding
    sourceComponent: Component {
        Item {
            anchors.fill: parent

            Timer {
                id: timer
                interval: 500
                running: housekeeping && counter.active
                onTriggered: {
                    touchInteractionHint.restart()
                    counter.increase()
                }
            }

            InteractionHintLabel {
                //% "Pull down to close all running apps"
                text: qsTrId("lipstick-jolla-home-la-pull_down_to_close_all_apps")
                anchors.bottom: parent.bottom
                opacity: touchInteractionHint.running ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation { duration: 1000 } }
            }

            TouchInteractionHint {
                id: touchInteractionHint
                direction: TouchInteraction.Down
                anchors.horizontalCenter: parent.horizontalCenter
                onRunningChanged: if (running && !housekeeping) stop() // stop looping if user leaves housekeeping
            }
        }
    }

    FirstTimeUseCounter {
        id: counter
        limit: 1
        defaultValue: 2 // don't display hint for existing users
        key: "/desktop/lipstick-jolla-home/close_all_apps_hint_count"
        ignoreSystemHints: true
    }
}
