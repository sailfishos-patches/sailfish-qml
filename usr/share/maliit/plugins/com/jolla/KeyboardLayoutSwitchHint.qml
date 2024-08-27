/*
 * Copyright (C) 2019 Jolla Ltd.
 *
 * Contact: Timur Kristóf <timur.kristof@jollamobile.com>
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list
 * of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list
 * of conditions and the following disclaimer in the documentation and/or other materials
 * provided with the distribution.
 * Neither the name of Nokia Corporation nor the names of its contributors may be
 * used to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

Loader {
    id: hint

    signal finished

    active: enabled && firstTimeUseCounter.active
    onActiveChanged: if (!active && firstTimeUseCounter.value === firstTimeUseCounter.limit) hint.finished()
    sourceComponent: Component {
        Item {
            anchors.fill: parent

            Connections {
                target: MInputMethodQuick
                onActiveChanged: {
                    if (MInputMethodQuick.active) {
                        firstTimeUseCounter.increase()
                        hintTimer.restart()
                    } else {
                        hintTimer.stop()
                        switchInteractionHint.stop()
                    }
                }
            }

            Timer {
                id: hintTimer
                interval: 1000
                onTriggered: switchInteractionHint.restart()
            }

            InteractionHintLabel {
                //: Hint for first time users that explains that the keyboard layout can be changed by swiping.
                //% "Swipe to change keyboard"
                text: qsTrId("text_input-la-swipe_change_keyboard_gesture_hint")
                anchors.bottom: parent.bottom
                opacity: switchInteractionHint.running ? 1.0 : 0.0
                Behavior on opacity { FadeAnimator { duration: 1000 } }
            }

            TouchInteractionHint {
                id: switchInteractionHint

                direction: TouchInteraction.Right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    FirstTimeUseCounter {
        id: firstTimeUseCounter

        limit: 2
        defaultValue: 0
        key: "/sailfish/text_input/switch_keyboard_hint_count"
    }
}
