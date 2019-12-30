import QtQuick 2.5
import Sailfish.Silica 1.0
import org.nemomobile.time 1.0

Item {
    id: root
    anchors.fill: parent
    property alias time: wallClock.time
    readonly property int seconds: time.getSeconds()
    readonly property int minutes: time.getMinutes()
    readonly property int hours: time.getHours() % 12

    WallClock {
        id: wallClock
        enabled: root.visible
        updateFrequency: WallClock.Second
    }

    Rectangle {
        id: outerCircle
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: Theme.paddingSmall / 2
        border.color: Theme.highlightColor
    }

    Item {
        id: hoursItem
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        rotation: visible ? hours * 30 + minutes / 10 : 0
        Behavior on rotation {
            enabled: visible
            RotationAnimator {
                duration: 1000
                direction: RotationAnimator.Shortest
            }
        }

        Rectangle {
            id: hoursHand
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: -radius
            width: 8
            height: (parent.height / 2 - outerCircle.border.width) / 2
            radius: width / 2
        }
    }

    Item {
        id: minutesItem
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        rotation: visible ? minutes * 6 + seconds / 10 : 0
        Behavior on rotation {
            enabled: visible
            RotationAnimator {
                duration: 1000
                direction: RotationAnimator.Shortest
            }
        }

        Rectangle {
            id: minutesHand
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: -radius
            width: 8
            height: (parent.height / 2 - outerCircle.border.width) / 5 * 4
            radius: width / 2
        }
    }

    Item {
        id: secondsItem
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        rotation: visible ? seconds * 6 : 0
        Behavior on rotation {
            enabled: visible
            RotationAnimator {
                duration: 1000
                direction: RotationAnimator.Shortest
            }
        }

        Rectangle {
            id: secondsHand
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.verticalCenter
            anchors.bottomMargin: -radius
            width: 4
            height: (parent.height / 2 - outerCircle.border.width) / 8 * 7
            radius: width / 2
        }
    }
}