import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    width: parent.width
    active: counter.active
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
                    counter.increase()
                    pageActive = true // delete binding
                }
            }

            anchors.fill: parent
            InteractionHintLabel {
                //% "Rotate the device to access scientific mode"
                text: qsTrId("calculator-la-scientific_calculator_hint")
                anchors.bottom: parent.bottom
                opacity: timer.running ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation { duration: 1000 } }
            }
            Timer {
                id: timer
                interval: 2400
            }
        }
    }
    FirstTimeUseCounter {
        id: counter
        limit: 2
        key: "/sailfish/calculator/scientific_calculator_hint_count"
    }
}
