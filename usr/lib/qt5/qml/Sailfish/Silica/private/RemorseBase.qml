/****************************************************************************************
**
** Copyright (C) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
** Contact: Martin Jones <martin.jones@jollamobile.com>
** All rights reserved.
**
** This file is part of Sailfish Silica UI component package
**
** You may use this file under the terms of BSD license as follows:
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**     * Redistributions of source code must retain the above copyright
**       notice, this list of conditions and the following disclaimer.
**     * Redistributions in binary form must reproduce the above copyright
**       notice, this list of conditions and the following disclaimer in the
**       documentation and/or other materials provided with the distribution.
**     * Neither the name of the Jolla Ltd nor the
**       names of its contributors may be used to endorse or promote products
**       derived from this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
** ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
** WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE FOR
** ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
** (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
** LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
** ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
** SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**
****************************************************************************************/

import QtQuick 2.6
import Sailfish.Silica.private 1.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root

    //% "Deleted"
    property string text: qsTrId("components-la-deleted")
    //% "Undo"
    property string cancelText: qsTrId("components-la-undo")
    property real leftMargin: Theme.horizontalPageMargin
    property real rightMargin: Theme.horizontalPageMargin
    property alias secondsHeight: row.height
    property alias pending: countdown.running
    property alias wrapMode: textLabel.wrapMode
    property alias horizontalAlignment: textLabel.horizontalAlignment
    property alias font: textLabel.font

    property int _timeout: 4000
    property int _seconds: (_timeout + 999) / 1000
    property int _secsRemaining: (_msRemaining + 999) / 1000
    property real _msRemaining: _timeout
    property Item _page
    property bool _triggered
    property real _contentOpacity
    property alias _countdown: countdown

    property Item _applicationWindow

    signal canceled
    signal triggered

    visible: false
    width: parent ? parent.width : Screen.width

    OverlayBackground.source: _applicationWindow && _applicationWindow._overlayBackgroundSource
    OverlayBackground.capture: parent && visible

    // Keep API behavior for clicked() signal, even if the undo action has moved to a separate button
    onClicked: cancel()
    highlighted: mouseArea.containsMouse && mouseArea.pressed

    onWindowChanged: {
        var contentItem = window ? window.contentItem : null
        if (contentItem) {
            var children = contentItem.children
            for (var i = 0; i < children.length; ++i) {
                var item = children[i]
                if (item.hasOwnProperty('_overlayBackgroundSource')) {
                    _applicationWindow = item
                    break
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: {
            if (hint.disappearHint.active && root.width > Screen.width / 2) {
                hint.state = "disappearHint"
                hint.disappearHint.increase()
            } else {
                _trigger()
            }
        }
    }

    GlassBackgroundBase {
        id: glassBackground

        width: root.width
        height: root.height
        z: -1   // Below the background item highlight

        backgroundItem: root._applicationWindow && root._applicationWindow._applicationBlur
        //      Homescreen values
        //        color: Theme.rgba(root.palette.overlayBackgroundColor, 0.65)
        color: Theme.rgba(root.palette.overlayBackgroundColor, 0.55)

        blending: true
    }

    Row {
        id: row

        property real cellWidth: (parent.width - ((repeater.count - 1) * spacing)) / repeater.count

        height: parent.height
        spacing: Math.ceil(Theme.pixelRatio)

        Repeater {
            id: repeater

            model: _seconds

            Rectangle {
                property real baseOpacity: root.palette.colorScheme === Theme.DarkOnLight ? 1.0 : 0.7

                width: row.cellWidth
                height: parent ? parent.height : 0
                color: Theme.rgba(root.palette.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                opacity: root._secsRemaining > Positioner.index ? baseOpacity : 0
                Behavior on opacity {
                    FadeAnimator {}
                }
            }
        }
    }

    Flow {
        states: State {
            name: "wrap"
            when: root.width <= Screen.width / 2
            PropertyChanges {
                target: textLabel
                width: parent.width - root.rightMargin
                height: root.height - undoButton.height
                horizontalAlignment: Text.AlignHCenter
                smallMode: fontMetrics.advanceWidth(textLabel.text) > textLabel.width
                           || fontMetrics.advanceWidth(undoLabel.text) > undoLabel.width
            }
            PropertyChanges {
                target: undoButton
                width: parent.width - root.rightMargin
                height: Math.max(Theme.itemSizeSmall, root.height / 3)
            }
            PropertyChanges {
                target: undoLabel
                width: parent.width
                horizontalAlignment: textLabel.horizontalAlignment
                truncationMode: TruncationMode.Fade
                x: 0
            }
        }

        opacity: root._contentOpacity
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: root.leftMargin
            verticalCenter: parent.verticalCenter
        }


        Label {
            id: textLabel

            readonly property real _contentWidth:
                root.leftMargin + fontMetrics.advanceWidth(text) + undoLabel.x
                + fontMetrics.advanceWidth(undoLabel.text) + root.rightMargin

            property bool smallMode: _contentWidth > root.width

            color: root.palette.highlightColor
            text: root.text
            width: parent.width - undoButton.width
            height: root.height
            wrapMode: Text.Wrap
            maximumLineCount: 2
            truncationMode: TruncationMode.Elide
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: smallMode ? Theme.fontSizeSmall : Theme.fontSizeMedium
            textFormat: Text.PlainText
        }

        FontMetrics {
            id: fontMetrics
            font.pixelSize: Theme.fontSizeMedium
        }

        MouseArea {
            id: undoButton

            onClicked: root.clicked(undefined)

            width: undoLabel.x + undoLabel.width + root.rightMargin
            height: root.height

            Label {
                id: undoLabel

                x: Theme.paddingMedium
                highlighted: parent.containsMouse && parent.pressed
                text: root.cancelText
                font.pixelSize: textLabel.font.pixelSize
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Item {
        id: hint

        property FirstTimeUseCounter disappearHint: FirstTimeUseCounter {
            limit: 1
            key: "/desktop/sailfish/hints/remorse_disappear_hint_count"
            ignoreSystemHints: true
        }

        onVisibleChanged: if (!visible) state = ""
        states: [
            State {
                name: "disappearHint"
                PropertyChanges {
                    target: countdown
                    paused: countdown.running
                }
                PropertyChanges {
                    target: undoButton
                    visible: false
                }
                PropertyChanges {
                    target: textLabel
                    wrapMode: Text.Wrap
                    width: textLabel.parent.width - root.rightMargin
                    font.pixelSize: Theme.fontSizeExtraSmall
                    //% "Undo banner will also disappear automatically"
                    text: qsTrId("components-la-remorse_disappear_hint")
                }
                PropertyChanges {
                    target: root
                    _seconds: 0
                    onClicked: {
                        hint.disappearHint.exhaust()
                        _trigger()
                    }
                }
            }
        ]

        Timer {
            interval: 2000
            running: hint.state !== ""
            onTriggered: _trigger()
        }
    }

    NumberAnimation {
        id: countdown
        target: root
        property: "_msRemaining"
        from: _timeout
        to: 0
        duration: _timeout
        onRunningChanged: {
            if (!running && _msRemaining == 0) {
                _trigger()
            }
        }
    }
}
