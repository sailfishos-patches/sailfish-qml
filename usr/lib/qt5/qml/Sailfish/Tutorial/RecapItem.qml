/*
 * Copyright (c) 2014 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Tutorial 1.0

SilicaItem {
    id: root
    anchors.fill: parent
    opacity: 0.0

    property int completedLessons
    property bool buttonsEnabled: showAnimation.running || root.opacity === 1.0
    property int retryLessonIndex
    property string recapText
    property bool exitWarningFits: root.height > (root.height - progress.y + buttons.height + 4*Theme.paddingLarge) + secondaryDescription.y + secondaryDescription.height

    states: [
        State {
            name: "start"
            PropertyChanges {
                target: label
                //: The primary label shown when the tutorial is started
                //% "Learn the basics of Sailfish OS"
                text: qsTrId("tutorial-la-learn_basics")
            }
            PropertyChanges {
                target: continueButton
                //% "Start"
                text: qsTrId("tutorial-bt-start")
                icon.source: ""
            }
            PropertyChanges {
                target: againButton
                visible: false
            }
            PropertyChanges {
                target: description
                text: {
                    if (Screen.sizeCategory >= Screen.Large) {
                        //: The secondary label shown when the tutorial is started (for large screen devices)
                        //% "Simply hold the device comfortably and follow the instructions on screen to learn how to navigate in Sailfish OS"
                        return qsTrId("tutorial-la-follow_the_instructions_tablet")
                    } else {
                        //: The secondary label shown when the tutorial is started (for small screen devices)
                        //% "Simply hold the device in one hand and follow the instructions on screen to learn how to navigate in Sailfish OS"
                        return qsTrId("tutorial-la-follow_the_instructions")
                    }
                }
            }
        },
        State {
            name: "finishedLessons"
            PropertyChanges {
                target: continueButton
                //% "Close tutorial"
                text: qsTrId("tutorial-bt-close_tutorial")
            }
            PropertyChanges {
                target: description
                text: {
                    var text = root.recapText

                    text += "\n\n"

                    //: Text shown at the end of the tutorial below tutorial-la-recap_incoming_call
                    //: (or tutorial-la-recap_pulley_menu_alternative in case of Jolla Launcher)
                    //% "This was the last part of the Tutorial. Now jump into the Sailfish experience!"
                    qsTrId("tutorial-la-recap_tutorial_completed")

                    return text
                }
            }
        },
        State {
            name: "exitWarning"
            PropertyChanges {
                target: label
                //% "Are you sure you want to skip the tutorial?"
                text: qsTrId("tutorial-la-skip_tutorial_confirmation")
            }
            PropertyChanges {
                target: description
                //% "The tutorial introduces you to the core features of Sailfish OS and helps you make the most out of your device."
                text: qsTrId("tutorial-la-skip_tutorial_disclaimer")
            }

            PropertyChanges {
                target: secondaryDescription

                visible: exitWarningFits
                //% "If you are too busy right now you can access the Tutorial app later from the App Grid."
                text: qsTrId("tutorial-la-skip_tutorial_secondary_disclaimer")
            }

            PropertyChanges {
                target: buttons
                anchors.bottomMargin: exitWarningFits ? 4*Theme.paddingLarge : 0
            }

            PropertyChanges {
                target: continueButton
                //% "Continue"
                text: qsTrId("tutorial-bt-continue")
                onClicked: root.show()
            }

            PropertyChanges {
                target: againButton
                text: qsTrId("tutorial-bt-close_tutorial")
                icon.source: "image://theme/icon-splus-cancel"
                onClicked: Qt.quit()
            }
            PropertyChanges {
                target: clearButton
                visible: false
            }
        }
    ]

    function show(pauseDuration) {
        showPause.duration = pauseDuration !== undefined ? pauseDuration : 500
        if (lessonCounter === 0) {
            root.state = "start"
        } else {
            if (lessonCounter === maxLessons) {
                root.state = "finishedLessons"
            } else {
                root.state = ""
            }

            completedLessons = lessonCounter
        }

        showAnimation.restart()
    }

    SequentialAnimation {
        id: showAnimation
        PauseAnimation { id: showPause }
        FadeAnimation {
            target: root
            property: "opacity"
            to: 1.0
            duration: 1000
        }
        ScriptAction {
            script: {
                if (allowSystemGesturesBetweenLessons) {
                    __quickWindow.flags &= ~(Qt.WindowOverridesSystemGestures)
                }
            }
        }
    }

    SequentialAnimation {
        id: hideAnimation
        ScriptAction {
            script: {
                if (allowSystemGesturesBetweenLessons) {
                    __quickWindow.flags |= Qt.WindowOverridesSystemGestures
                }
            }
        }
        FadeAnimation {
            target: root
            property: "opacity"
            to: 0.0
            duration: 1000
        }
        ScriptAction { script: showLesson() }
    }

    Rectangle {
        anchors.fill: parent
        color: root.palette.highlightDimmerColor
        opacity: 0.9
    }

    InfoLabel {
        id: label
        y: Math.round(Screen.height/7)

        //% "Well done!"
        text: qsTrId("tutorial-la-well_done")
    }

    Label {
        id: description
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        x: Theme.horizontalPageMargin
        anchors {
            top: label.bottom
            topMargin: Theme.paddingLarge
        }
        width: parent.width - 2 * x
        text: root.recapText
    }

    Label {
        id: secondaryDescription
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        x: Theme.horizontalPageMargin
        anchors {
            top: description.bottom
            topMargin: Theme.paddingLarge
        }
        width: parent.width - 2 * x
    }

    IconButton {
        id: clearButton

        anchors {
            top: parent.top
            right: parent.right
            margins: Theme.paddingLarge
        }

        icon.source: "image://theme/icon-m-clear"

        onClicked: {
            if (root.state === "finishedLessons" || allowSystemGesturesBetweenLessons) {
                Qt.quit()
            } else {
                root.state = "exitWarning"
            }
        }
    }

    ButtonLayout {
        id: buttons

        anchors {
            bottom: progress.top
            bottomMargin: 4*Theme.paddingLarge
        }
        preferredWidth: Theme.buttonWidthMedium

        Button {
            id: continueButton
            enabled: buttonsEnabled
            layoutDirection: Qt.RightToLeft
            icon.source: "image://theme/icon-splus-right"

            onClicked: {
                lessonCounter++
                retryLessonIndex = lessonCounter
                hideAnimation.restart()
            }

            text: qsTrId("tutorial-bt-continue")
        }

        SecondaryButton {
            id: againButton

            onClicked: {
                lessonCounter = retryLessonIndex
                hideAnimation.restart()
            }

            //% "Try again"
            text: qsTrId("tutorial-bt-try_again")

            ButtonLayout.newLine: true
            enabled: buttonsEnabled
            visible: { true }
        }
    }

    Row {
        id: progress

        anchors {
            bottom: parent.bottom
            bottomMargin: 3 * Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        spacing: Theme.paddingMedium
        visible: completedLessons > 0

        Repeater {
            model: maxLessons
            HighlightImage {
                source: "image://theme/graphic-tutorial-progress-" + (index + 1)
                opacity: (completedLessons > index) ? 1.0 : Theme.opacityHigh
                highlighted: true
            }
        }
    }
}
