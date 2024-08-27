/*
 * Copyright (c) 2016 - 2021 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    width: parent.width
    active: counter.active
    onActiveChanged: if (active) active = true // remove binding
    sourceComponent: Component {
        Item {
            property bool pageActive: calculatorPage.status == PageStatus.Active && Qt.application.active

            onPageActiveChanged: {
                if (pageActive) {

                    // If the app is started in landscape no need to advertise
                    // scientific mode, user can find it without help
                    if (calculatorPage.isPortrait) {
                        timer.restart()
                    }
                    pageActive = true // delete binding
                }
            }

            anchors.fill: parent
            InteractionHintLabel {
                //% "Drag the panel open to enable scientific mode"
                text: qsTrId("calculator-la-scientific_calculator_hint")
                anchors.bottom: parent.bottom
                opacity: timer.running ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation { duration: 1000 } }
            }
            Timer {
                id: timer
                interval: 2400
                onTriggered: counter.increase()
            }
        }
    }
    FirstTimeUseCounter {
        id: counter
        limit: 1
        key: "/sailfish/calculator/scientific_calculator_hint_count"
    }
}
