/*
 * Copyright (c) 2014 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Lesson {
    id: root

    //: This text has a full stop at the end unlike the other "recap labels" because
    //: it's shown together with tutorial-la-recap_tutorial_completed
    //% "Now you know what to do when you get a call."
    recapText: qsTrId("tutorial-la-recap_incoming_call")

    opacity: 0.0

    Component.onCompleted: {
        timeline.restart()
    }

    SequentialAnimation {
        id: timeline
        PauseAnimation { duration: 1000 }
        FadeAnimation {
            target: root
            to: 1.0
            duration: 500
        }
        PauseAnimation { duration: 1500 }
        ScriptAction  {
            script: {
                //% "This is an incoming call"
                hintLabel.text = qsTrId("tutorial-la-incoming_call")
                hintLabel.opacity = 1.0
            }
        }
        PauseAnimation { duration: 3000 }
        ScriptAction  {
            script: {
                hintLabel.opacity = 0.0
            }
        }
        PauseAnimation { duration: 1000 }
        ScriptAction  {
            script: {
                //% "The lines at the top and bottom indicate the pulley menus"
                hintLabel.text = qsTrId("tutorial-la-pulley_explanation")
                hintLabel.opacity = 1.0
                answerMenu.busy = true
                rejectMenu.busy = true
            }
        }
        PauseAnimation { duration: 3000 }
        ScriptAction  {
            script: {
                hintLabel.opacity = 0.0
            }
        }
        PauseAnimation { duration: 1000 }
        ScriptAction  {
            script: {
                //% "Pull down to accept the call"
                hintLabel.text = qsTrId("tutorial-la-pull_down_to_answer")
                hintLabel.opacity = 1.0
                hintLabel.atBottom = true
                hint.start()
                answerMenu.busy = false
                answerMenu.acceptAction = true
                rejectMenu.busy = false
                touchBlocker.enabled = false
            }
        }
    }

    SequentialAnimation {
        id: timeline2
        PauseAnimation { duration: 1000 }
        ScriptAction  {
            script: {
                //% "Pull up to ignore the call"
                hintLabel.text = qsTrId("tutorial-la-pull_down_to_ignore")
                hintLabel.opacity = 1.0
                hintLabel.atBottom = false
                hint.direction = TouchInteraction.Up
                hint.start()
                rejectMenu.acceptAction = true
                touchBlocker.enabled = false
            }
        }
    }

    SequentialAnimation {
        id: closeAnimation
        PauseAnimation { duration: 500 }
        FadeAnimation {
            target: root
            to: 0.0
            duration: 2000
        }
    }

    Image {
        fillMode: Image.PreserveAspectFit
        parent: applicationBackground
        width: parent.width
        opacity: root.opacity
        source: Qt.resolvedUrl("file:///usr/share/sailfish-tutorial/graphics/tutorial-phone-incoming-call.jpg")
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: height

        property bool menuActive: answerMenu.active || rejectMenu.active

        onMenuActiveChanged: {
            if (answerMenu.acceptAction || rejectMenu.acceptAction) {
                hintLabel.opacity = menuActive ? 0.0 : 1.0
                if (menuActive)
                    hint.stop()
                else
                    hint.start()
            }
        }

        SequentialAnimation {
            id: pulleyAnimationHint

            property real distance: Theme.paddingMedium

            running: !flickable.dragging
            loops: Animation.Infinite
            alwaysRunToEnd: true
            PauseAnimation { duration: 800 }
            NumberAnimation {
                target: content
                property: "y"
                from: 0
                to: -pulleyAnimationHint.distance
                duration: 200
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: content
                property: "y"
                from: -pulleyAnimationHint.distance
                to: pulleyAnimationHint.distance
                duration: 400
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                target: content
                property: "y"
                from: pulleyAnimationHint.distance
                to: 0
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        Item {
            id: content
            width: root.width
            height: root.height

            Column {

                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: rejectLabel.top
                    bottomMargin: Theme.itemSizeSmall
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }

                Label {
                    //: The name of the caller
                    //% "Friend"
                    text: qsTrId("tutorial-la-friend")
                    horizontalAlignment: Text.AlignHCenter
                    font { family: Theme.fontFamilyHeading; pixelSize: Theme.fontSizeHuge }
                    width: parent.width
                }

                Label {
                    id: callingLabel
                    //: Needs to match with voicecall-la-calling
                    //% "calling"
                    text: qsTrId("tutorial-la-calling")
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    font { family: Theme.fontFamilyHeading; pixelSize: Theme.fontSizeLarge }
                }
            }

            Image {
                id: answerIcon
                y: Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                source: "image://theme/icon-l-answer?#00CC00"
            }

            Image {
                id: rejectIcon
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: Theme.paddingMedium
                }
                source: "image://theme/icon-l-reject?#CC0000"
            }


            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    top: answerIcon.bottom
                    topMargin: Theme.paddingSmall
                }
                //: Action to accept the incoming call
                //% "Pull down to answer"
                text: qsTrId("voicecall-me-pull_down_to_answer")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: answerMenu.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }

            Label {
                id: rejectLabel
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    bottom: rejectIcon.top
                }
                //: Action to silence the incoming call
                //% "Pull up to silence"
                text: qsTrId("voicecall-me-pull_up_to_silence")
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                color: rejectMenu.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }


        HintLabel {
            id: hintLabel
            opacity: 0.0
        }

        PullDownMenu {
            id: answerMenu

            property bool acceptAction

            highlightColor: "#80ff91"
            backgroundColor: "#19ff38"
            colorScheme: Theme.LightOnDark
            quickSelect: true

            MenuItem {
                color: "#aaff80"
                //: Needs to match with voicecall-me-answer
                //% "Answer"
                text: qsTrId("tutorial-me-answer")
                onClicked: {
                    if (answerMenu.acceptAction) {
                        answerMenu.acceptAction = false
                        touchBlocker.enabled = true
                        timeline2.restart()
                    }
                }
            }

            Item {
                height: Theme.itemSizeExtraSmall
                width: parent.width
            }
        }

        PushUpMenu {
            id: rejectMenu

            property bool acceptAction

            highlightColor: "#ff8084"
            backgroundColor: "#ff1a22"
            colorScheme: Theme.LightOnDark
            quickSelect: true

            Item {
                height: Theme.itemSizeExtraSmall
                width: parent.width
            }

            MenuItem {
                color: "#ff8080"
                //: Action to silence the incoming call
                //% "Pull up to silence"
                text: qsTrId("voicecall-me-pull_up_to_silence")
                onClicked: {
                    if (rejectMenu.acceptAction) {
                        pulleyAnimationHint.paused = true
                        rejectMenu.acceptAction = false
                        touchBlocker.enabled = true
                        closeAnimation.restart()
                        lessonCompleted()
                    }
                }
            }
        }
    }

    TouchInteractionHint {
        id: hint
        direction: TouchInteraction.Down
        interactionMode: TouchInteraction.Swipe
        loops: Animation.Infinite
    }

    MouseArea {
        id: touchBlocker
        anchors.fill: parent
        preventStealing: true
    }
}
