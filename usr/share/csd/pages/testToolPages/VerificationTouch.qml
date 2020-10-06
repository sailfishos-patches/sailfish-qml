/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import "model.js" as Model
import ".."

CsdTestPage {
    id: page

    backNavigation: false

    property int targetCellSize: 60 * Theme.pixelRatio
    property int horizontalCells: Math.floor(Screen.width / targetCellSize)
    property int verticalCells: Math.floor(Screen.height / targetCellSize)
    property real cellWidth: Screen.width / horizontalCells
    property real cellHeight: Screen.height / verticalCells

    Private.WindowGestureOverride {
        id: windowGestureOverride
        active: true
    }

    Component.onCompleted: Model.initializeGridData(2 * (horizontalCells + verticalCells) - 4)

    Row {
        id: topRow

        anchors.top: parent.top

        Repeater {
            id: topRepeater
            model: horizontalCells

            Rectangle {
                width: cellWidth
                height: cellHeight
                color: index % 2 == 0 ? "grey" : "white"
            }
        }
    }

    Row {
        id: bottomRow

        anchors.bottom: parent.bottom

        Repeater {
            id: bottomRepeater
            model: horizontalCells

            Rectangle {
                width: cellWidth
                height: cellHeight
                color: index % 2 == 0 ? "white" : "grey"
            }
        }
    }

    Column {
        id: leftColumn

        anchors {
            top: topRow.bottom
            left: parent.left
        }

        Repeater {
            id: leftRepeater
            model: verticalCells - 2

            Rectangle {
                width: cellWidth
                height: cellHeight
                color: index % 2 == 0 ? "white" : "grey"
            }
        }
    }

    Column {
        id: rightColumn

        anchors {
            top: topRow.bottom
            right: parent.right
        }

        Repeater {
            id: rightRepeater

            model: verticalCells - 2

            Rectangle {
                width: cellWidth
                height: cellHeight
                color: index % 2 == 0 ? "white" : "grey"
            }
        }
    }

    Label {
        anchors.centerIn: parent
        width: parent.width - leftColumn.width - rightColumn.width - 2*Theme.paddingMedium
        font.pointSize: Theme.fontSizeSmall
        //% "Touch and slide over surrounding grids with your finger."
        text: qsTrId("csd-la-touch_and_slide_grids")
        wrapMode: Text.Wrap
    }

    Column {
        spacing: Theme.paddingMedium

        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: bottomRow.top
            bottomMargin: Theme.paddingLarge
        }

        FailButton {
            onClicked: {
                setTestResult(false)
                windowGestureOverride.reset()
                testCompleted(true)
            }
        }

        Button {
            visible: !isContinueTest
            //% "Exit"
            text: qsTrId("csd-la-exit");
            onClicked: {
                windowGestureOverride.reset()
                testCompleted(true)
            }
        }
    }

    MouseArea {
        z: -1
        anchors.fill: parent

        property point lastIndex: Qt.point(-1, -1)

        function modelIndex(horizontalIndex, verticalIndex) {
            if (verticalIndex === 0)
                return horizontalIndex
            else if (verticalIndex === verticalCells-1)
                return horizontalCells + verticalCells + (horizontalCells - horizontalIndex - 1) - 2
            else if (horizontalIndex === horizontalCells-1)
                return horizontalCells + verticalIndex - 1
            else if (horizontalIndex === 0)
                return horizontalCells + verticalCells + horizontalCells + (verticalCells - verticalIndex - 1) - 3
            else
                return undefined
        }

        function modelItem(horizontalIndex, verticalIndex) {
            if (verticalIndex === 0)
                return topRepeater.itemAt(horizontalIndex)
            else if (verticalIndex === verticalCells-1)
                return bottomRepeater.itemAt(horizontalIndex)
            else if (horizontalIndex === horizontalCells-1)
                return rightRepeater.itemAt(verticalIndex-1)
            else if (horizontalIndex === 0)
                return leftRepeater.itemAt(verticalIndex-1)
            else
                return null
        }

        onPressed: {
            lastIndex = Qt.point(Math.floor(mouseX / cellWidth), Math.floor(mouseY / cellHeight))
        }
        onPositionChanged: {
            lastIndex = Qt.point(Math.floor(mouseX / cellWidth), Math.floor(mouseY / cellHeight))
        }

        onLastIndexChanged: {
            if (lastIndex === Qt.point(-1, -1))
                return

            var index = modelIndex(lastIndex.x, lastIndex.y)
            if (index === undefined)
                return

            var item = modelItem(lastIndex.x, lastIndex.y)
            if (item)
                item.color = "green"

            if (Model.allPass(index)) {
                setTestResult(true)
                windowGestureOverride.reset()
                testCompleted(true)
            }
        }
    }
}
