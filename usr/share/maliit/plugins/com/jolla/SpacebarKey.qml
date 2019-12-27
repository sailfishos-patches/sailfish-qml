// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.keyboard 1.0

CharacterKey {
    id: characterKey

    property alias languageLabel: textField.text
    property bool expandingKey: true
    property bool enableLanguageIndicatorFlash: languageLabel !== ""
    property real _normalOpacity: 0.07
    property real _pressedOpacity: 0.6

    caption: " "
    captionShifted: " "
    showPopper: false
    separator: SeparatorState.HiddenSeparator
    showHighlight: false
    key: Qt.Key_Space

    function flashLanguageIndicator() {
        var animation = flashLanguageIndicatorComponent.createObject(textField)
        animation.start()
    }

    Rectangle {
        id: background
        color: parent.pressed ? Theme.highlightBackgroundColor : Theme.primaryColor
        opacity: parent.pressed ? _pressedOpacity : _normalOpacity
        radius: geometry.keyRadius

        anchors.fill: parent
        anchors.margins: Theme.paddingMedium
    }

    Text {
        id: textField
        x: Theme.paddingMedium + 2
        width: parent.width - 2*x
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: languageCode
        color: Theme.primaryColor
        opacity: .4
        font.pixelSize: Theme.fontSizeSmall
        fontSizeMode: Text.Fit
    }

    Connections {
        target: keyboard.layout
        // TODO: use `enabled: enableLanguageIndicatorFlash` after upgrade to Qt >= 5.7
        onFlashLanguageIndicator: if (enableLanguageIndicatorFlash) flashLanguageIndicator()
    }

    Component {
        id: flashLanguageIndicatorComponent

        SequentialAnimation {
            ParallelAnimation {
                FadeAnimator {
                    target: background
                    duration: 120
                    from: _normalOpacity
                    to: Theme.highlightBackgroundOpacity
                }
                ColorAnimation {
                    target: background
                    duration: 120
                    from: Theme.primaryColor
                    to: Theme.highlightBackgroundColor
                }
            }
            ParallelAnimation {
                FadeAnimator {
                    target: background
                    duration: 60
                    from: Theme.highlightBackgroundOpacity
                    to: _normalOpacity
                }
                ColorAnimation {
                    target: background
                    duration: 60
                    from: Theme.highlightBackgroundColor
                    to: Theme.primaryColor
                }
            }
            ParallelAnimation {
                FadeAnimator {
                    target: background
                    duration: 120
                    from: _normalOpacity
                    to: Theme.highlightBackgroundOpacity
                }
                ColorAnimation {
                    target: background
                    duration: 120
                    from: Theme.primaryColor
                    to: Theme.highlightBackgroundColor
                }
            }
            ParallelAnimation {
                FadeAnimator {
                    target: background
                    duration: 60
                    from: Theme.highlightBackgroundOpacity
                    to: _normalOpacity
                }
                ColorAnimation {
                    target: background
                    duration: 60
                    from: Theme.highlightBackgroundColor
                    to: Theme.primaryColor
                }
            }

            ScriptAction {
                script: {
                    // The above animations messed up these bindings, so re-connect them here
                    background.opacity = Qt.binding(function() { return characterKey.pressed ? _pressedOpacity : _normalOpacity })
                    background.color = Qt.binding(function() { return characterKey.pressed ? Theme.highlightBackgroundColor : Theme.primaryColor })

                    // Destroy dynamically created transition instance
                    destroy()
                }
            }

        }
    }
}
