import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    property alias text: buttonLabel.text
    property alias icon: buttonIcon

    property bool offscreen
    readonly property real offscreenPeekWidth: Theme.paddingMedium + iconContainer.width + Theme.paddingSmall
    property bool showIconWhenOffscreen: true

    property bool animate
    property int animationDuration: 350 // Same as removal animation in BaseEditor
    readonly property real revealedContentOpacity: _revealedContentOpacity
    readonly property bool busy: toButtonState.running || toDefaultState.running
    property bool highlighted: down
    readonly property bool down: mouseArea.containsMouse

    property real _revealedContentOpacity

    signal clicked()
    signal enteredButtonMode()

    width: parent.width
    height: Theme.itemSizeMedium

    Label {
        id: buttonLabel

        x: iconContainer.x - Theme.paddingSmall - width
        y: parent.height/2 - height/2

        font.pixelSize: Theme.fontSizeMedium
        color: mouseArea.containsPress ? Theme.highlightColor : Theme.primaryColor
        truncationMode: TruncationMode.Fade
        horizontalAlignment: Text.AlignRight
    }

    Item {
        id: iconContainer

        x: root.width - width
        y: parent.height/2 - height/2
        width: Theme.itemSizeSmall
        height: Theme.itemSizeMedium

        HighlightImage {
            id: buttonIcon

            anchors.centerIn: parent
            highlighted: mouseArea.containsPress || root.highlighted
        }
    }

    // Close vkb if user clicks within the button area but outside of text+icon.
    MouseArea {
        anchors.fill: parent
        enabled: root.state === "" && !root.busy
        onPressed: {
            root.focus = true
            mouse.accepted = false
        }
    }

    MouseArea {
        id: mouseArea

        x: buttonLabel.x
        width: buttonLabel.width + Theme.paddingSmall + iconContainer.width
        height: parent.height
        enabled: root.state === "" && !root.busy

        onClicked: root.clicked()
    }

    states: [
        State {
            name: "offscreen"
            when: root.offscreen

            PropertyChanges {
                target: root
                x: -root.width + root.offscreenPeekWidth
            }
            PropertyChanges {
                target: buttonLabel
                opacity: 0
            }
            PropertyChanges {
                target: iconContainer
                opacity: showIconWhenOffscreen ? 1 : 0
            }
            PropertyChanges {
                target: root
                _revealedContentOpacity: 1
            }
        }
    ]

    transitions: [
        Transition {
            id: toDefaultState

            from: ""; to: "offscreen"
            enabled: root.animate

            SequentialAnimation {
                PauseAnimation {
                    duration: root.animationDuration / 2
                }
                FadeAnimation {
                    target: root
                    property: "_revealedContentOpacity"
                    duration: root.animationDuration
                }
            }
            NumberAnimation {
                target: root
                property: "x"
                duration: root.animationDuration
                easing.type: Easing.InOutQuad
            }
            FadeAnimation {
                targets: [buttonLabel, iconContainer]
                duration: root.animationDuration / 2
            }
        },
        Transition {
            id: toButtonState

            from: "offscreen"; to: ""
            enabled: root.animate

            SequentialAnimation {
                ParallelAnimation {
                    FadeAnimation {
                        target: root
                        property: "_revealedContentOpacity"
                        duration: root.animationDuration / 2
                    }
                    NumberAnimation {
                        target: root
                        property: "x"
                        duration: root.animationDuration
                        easing.type: Easing.InOutQuad
                    }
                    FadeAnimation {
                        target: buttonLabel
                        duration: root.animationDuration
                    }
                }
                ScriptAction {
                    script: root.enteredButtonMode()
                }
            }
        }
    ]
}
