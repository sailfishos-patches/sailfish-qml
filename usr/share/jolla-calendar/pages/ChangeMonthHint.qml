import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    anchors.fill: parent
    active: counter.active
    sourceComponent: Component {
        Item {
            property bool pageActive: root.status == PageStatus.Active
            onPageActiveChanged: {
                if (pageActive) {
                    timer.restart()
                    counter.increase()
                    pageActive = false
                }
            }

            anchors.fill: parent
            Timer {
                id: timer
                interval: 500
                onTriggered: touchInteractionHint.restart()
            }

            InteractionHintLabel {
                //: Swipe here to change month
                //% "Swipe here to change month"
                text: qsTrId("calendar-la-change_month_hint")
                anchors.bottom: parent.bottom
                opacity: touchInteractionHint.running ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation { duration: 1000 } }
            }
            TouchInteractionHint {
                id: touchInteractionHint

                direction: TouchInteraction.Right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    FirstTimeUseCounter {
        id: counter
        limit: 3
        defaultValue: 1 // display hint twice for existing users
        key: "/sailfish/calendar/change_month_hint_count"
    }
}
