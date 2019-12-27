import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

Loader {
    property bool sneakPeekActive

    anchors.fill: parent
    active: counter.active

    sourceComponent: Component {
        InteractionHintLabel {
            //% "Sneak peek occurs when device is uncovered. Double tap to wake it up fully"
            text: qsTrId("lipstick-jolla-home-la-double_tap_to_wake_up")
            anchors.bottom: parent.bottom
            opacity: sneakPeekActive ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation { duration: 1000 } }
        }
    }
    FirstTimeUseCounter {
        id: counter
        limit: 3
        defaultValue: 1 // display hint twice for existing users
        key: "/desktop/lipstick-jolla-home/sneak_peek_hint_count"
    }

    onSneakPeekActiveChanged: if (sneakPeekActive) counter.increase()
}
