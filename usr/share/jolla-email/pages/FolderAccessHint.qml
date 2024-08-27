/*
 * Copyright (c) 2014 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    id: root

    property bool pageActive

    anchors.fill: parent
    active: counter.active && app.numberOfAccounts > 0
    sourceComponent: Component {
        Item {
            anchors.fill: parent

            Connections {
                target: root
                onPageActiveChanged: {
                    if (root.pageActive) {
                        touchInteractionHint.restart()
                        counter.increase()
                        root.pageActive = false
                    }
                }
            }

            InteractionHintLabel {
                //: Swipe left to access your Email folders
                //% "Swipe left to access your Email folders"
                text: qsTrId("email-la-folder_access_hint")
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
        key: "/sailfish/email/folder_access_hint_count"
    }
}
