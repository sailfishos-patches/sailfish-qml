import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    anchors.fill: parent
    active: counter.active && enabled
    sourceComponent: Component {
        Item {
            property bool pageActive: conversationPage.status == PageStatus.Active
            onPageActiveChanged: {
                if (pageActive) {
                    touchInteractionHint.restart()
                    pageActive = false
                    counter.increase()
                }
            }

            anchors.fill: parent
            InteractionHintLabel {
                //: Swipe left to access the contact card
                //% "Swipe left to access the contact card"
                text: qsTrId("messages-la-access_contact_card_hint")
                anchors.bottom: parent.bottom
                opacity: touchInteractionHint.running ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation { duration: 1000 } }
            }
            TouchInteractionHint {
                id: touchInteractionHint

                direction: TouchInteraction.Left
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    FirstTimeUseCounter {
        id: counter
        limit: 3
        defaultValue: 1 // display hint twice for existing users
        key: "/sailfish/messages/access_contact_card_hint_count"
    }
}
