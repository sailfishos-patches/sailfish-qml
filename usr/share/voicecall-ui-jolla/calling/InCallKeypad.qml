import QtQuick 2.0
import Sailfish.Silica 1.0
import QOfono 0.2

DockedPanel {
    id: root

    property Item button

    width: isPortrait ? parent.width : parent.width/2
    dock: isPortrait ? Dock.Bottom : Dock.Right
    height: isPortrait ? content.height + (button ? button.height + button.bottomMargin : 0)
                       : parent.height
    interactive: false
    visible: expanded

    onOpenChanged: dialerSwitch.checked = open
    function fade() {
        fadeAnim.start()
    }

    SequentialAnimation {
        id: fadeAnim
        FadeAnimation { target: content; to: 0.0 }
        ScriptAction { script: { root.hide(true); content.opacity = 1.0 } }
    }

    MouseArea {
        // MouseArea ensures DockedPanel filtering steals child events.
        anchors.fill: parent
        Column {
            id: content
            width: parent.width
            y: isPortrait ? 0 : parent.height/2 - height/2

            Item {
                visible: isPortrait
                height: 2 * Theme.paddingLarge
                width: parent.width
                Icon {
                    width: parent.width
                    source: "image://theme/graphic-gradient-edge"
                }
            }

            Keypad {
                id: dialer

                // The timer will trigger 5 times at 50 millisecond intervals, the first interval
                // gives the path view time to detect a flick and steal the mouse grab before the
                // DTMF tone starts, the next 4 intervals ensure the tone plays for at least 200
                // milliseconds.
                property bool dtmfPlaying: (dtmfTimer.running || buttonDown) && dtmfStep > 0
                property int dtmfStep: -1
                property bool buttonDown

                onPressed: {
                    buttonDown = true
                    telephony.startDtmfTone(number)
                    dtmfStep = 0
                    dtmfTimer.restart()
                }
                onReleased: buttonDown = false
                onCanceled: buttonDown = false
                onClicked: telephony.updateDtmfToneHistory(number)
                onDtmfPlayingChanged: {
                    if (!dtmfPlaying) {
                        telephony.stopDtmfTone()
                        dtmfStep = -1
                    }
                }

                Timer {
                    id: dtmfTimer

                    interval: 50
                    repeat: true
                    onTriggered: {
                        if (++dialer.dtmfStep == 5) {
                            stop()
                        }
                    }
                }
            }
        }
    }
}
