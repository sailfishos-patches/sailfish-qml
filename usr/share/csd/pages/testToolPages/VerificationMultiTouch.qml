/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import QtQuick.Window 2.2 as QtQuick
import ".."

CsdTestPage {
    id: page
    backNavigation: false
    onOrientationChanged: canvas.clear()

    Private.WindowGestureOverride {
        id: windowGestureOverride
        active: true
    }

    Canvas {
        id: canvas

        anchors.fill: parent

        MultiPointTouchArea {
            anchors.fill: parent
            minimumTouchPoints: 1
            maximumTouchPoints: 10

            property var availableColors: ["blue", "red", "purple", "orange", "green", "hotpink", "aqua", "greenyellow", "brown", "salmon"]
            property var assignedColors: new Object
            readonly property real dotDiameter: QtQuick.Screen.pixelDensity * 2 // 2 mm

            onPressed: {
                for (var i = 0; i < touchPoints.length; ++i) {
                    var pointId = touchPoints[i].pointId
                    if (!(pointId in assignedColors))
                        assignedColors[pointId] = availableColors.pop()
                }
            }

            onReleased: {
                for (var i = 0; i < touchPoints.length; ++i) {
                    var pointId = touchPoints[i].pointId
                    availableColors.push(assignedColors[pointId])
                    delete assignedColors[pointId]
                }
            }

            onTouchUpdated: {
                var ctx = canvas.getContext("2d")
                ctx.lineWidth = 2
                for (var i = 0; i < touchPoints.length; ++i) {
                    var touchPoint = touchPoints[i]

                    ctx.fillStyle = assignedColors[touchPoint.pointId]
                    ctx.beginPath()
                    ctx.roundedRect(touchPoint.x - dotDiameter/2, touchPoint.y - dotDiameter/2, dotDiameter, dotDiameter, dotDiameter/2, dotDiameter/2)
                    ctx.closePath()
                    ctx.fill()
                    coordinatesTextX.text = "x: " + Math.round(touchPoint.x)
                    coordinatesTextY.text = "y: " + Math.round(touchPoint.y)
                }

                canvas.requestPaint()
            }
        }

        function clear() {
            var ctx = canvas.getContext("2d")
            ctx.fillStyle = '#000000'
            ctx.fillRect(0, 0, canvas.width, canvas.height)
            canvas.requestPaint()
        }

        Component.onCompleted: clear()
    }

    PageHeader {
        //% "Multi-touch"
        title: qsTrId("csd-he-multi-touch")
        //% "Resolution: "
        description: qsTrId("csd-he-resolution") + canvas.canvasSize.width.toString() + "×" + canvas.canvasSize.height.toString()
    }

    Column {
        y: Theme.paddingLarge
        x: Theme.paddingLarge
        spacing: Theme.paddingMedium
        width: Screen.width/3

        PassButton {
            id: passButton
            onClicked: {
                setTestResult(true)
                windowGestureOverride.reset()
                testCompleted(true)
            }
        }

        FailButton {
            id: failButton
            onClicked: {
                setTestResult(false)
                windowGestureOverride.reset()
                testCompleted(true)
            }
        }

        Button {
            id: clearButton
            //% "Clear"
            text: qsTrId("csd-la-clear")
            onClicked: canvas.clear()
        }

        Label {
            id: coordinatesTextX
        }

        Label {
            id: coordinatesTextY
        }
    }
}
