import QtQuick 2.0
import "../common"

Loader {
    property bool largeMode

    property real prePadding
    property real postPadding

    property real timeTextWidth: item && item.hasOwnProperty("timeTextWidth") ? item.timeTextWidth : 0

    source: largeMode ? "TimerItemLarge.qml" : "TimerItemSmall.qml"

    TimerClock {
        id: clock
        keepRunning: root.update
    }

    Binding {
        target: item
        property: "prePadding"
        value: prePadding
    }

    Binding {
        target: item
        property: "postPadding"
        value: postPadding
    }

    Binding {
        target: item
        property: "timerClock"
        value: clock
    }

    Binding {
        target: clockView
        property: "timerClock"
        value: clock
        when: model.index === 0
    }
}
