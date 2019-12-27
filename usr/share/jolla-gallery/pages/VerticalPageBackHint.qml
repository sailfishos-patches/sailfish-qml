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
                //% "Swipe down to go to previous view"
                text: qsTrId("gallery-la-swipe_down_to_go_back")
                anchors.bottom: parent.bottom
                opacity: touchInteractionHint.running ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation { duration: 1000 } }
                textColor: Theme.highlightFromColor(Theme.highlightColor, Theme.LightOnDark)
                backgroundColor: Theme.rgba(Theme.highlightDimmerFromColor(Theme.highlightDimmerColor,  Theme.LightOnDark), 0.9)
            }
            TouchInteractionHint {
                id: touchInteractionHint

                color: Theme.lightPrimaryColor
                direction: TouchInteraction.Down
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    FirstTimeUseCounter {
        id: counter
        limit: 2
        key: "/sailfish/gallery/vertical_page_back_hint"
    }
}
