/*
 * Copyright (c) 2013 - 2021 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calculator 1.0

PanelBackground {
    id: calculatorPanel

    property Calculation calculation
    property QtObject _feedbackEffect
    property Item advancedPanel: advanced

    signal clear
    signal buttonClicked
    signal menuClosed

    Component.onCompleted: {
        // avoid hard dependency to QtFeedback module
        _feedbackEffect = Qt.createQmlObject("import QtQuick 2.0; import QtFeedback 5.0; ThemeEffect { effect: ThemeEffect.PressWeak }",
                           calculatorPanel, 'ThemeEffect');
    }

    width: parent.width
    height: numericColumn.height

    states: State {
        name: "advanced"
        when: calculatorPage.isLandscape

        PropertyChanges {
            target: calculatorPanel
            height: numericColumn.height
        }
        PropertyChanges {
            target: advanced
            visible: true
            width: squareWidth * 3
            height: parent.height
            clip: false
            open: false
            dragging: false
        }
        AnchorChanges {
            target: advanced
            anchors.bottom: parent.bottom
        }
        AnchorChanges {
            target: operations
            anchors.right: parent.right
        }
        AnchorChanges {
            target: numericColumn
            anchors.left: undefined
            anchors.horizontalCenter: middlePlaceholder.horizontalCenter
        }
    }

    Item {
        id: advanced

        readonly property bool animating: showTimer.running || animation.running
        readonly property alias animationDuration: animation.duration
        readonly property alias maximumHeight: advancedFlow.implicitHeight
        property bool dragging: dragArea.drag.active
        property bool open: showTimer.running
        property real lastY
        property real lastYOnDirectionChange

        clip: dragging || animating
        width: parent.width
        height: -y
        visible: dragging || open || animating

        onYChanged: {
            // check direction and set open accordingly
            if (dragging) {
                if ((lastY > y && lastYOnDirectionChange < y) || (lastY < y && lastYOnDirectionChange > y)) {
                    lastYOnDirectionChange = y
                }
                if (Math.abs(lastYOnDirectionChange - y) >= dragArea.drag.threshold) {
                    open = lastYOnDirectionChange > y
                }
                lastY = y
            }
        }
        onDraggingChanged: {
            if (dragging) {
                lastY = y
                lastYOnDirectionChange = y
            } else {
                // animate to fully open or closed position after dragging
                animate()
            }
        }

        Timer {
            // Keeps this panel open for a little while when the app is started and hint is shown
            id: showTimer
            running: hint.active
            interval: 3200
            onRunningChanged: if (running) running = true // break binding
            onTriggered: {
                advanced.open = false
                advanced.animate()
            }
        }

        Binding {
            target: advanced
            property: "y"
            value: -advanced.maximumHeight 
            when: showTimer.running
        }

        ParallelAnimation {
            id: animation
            property real targetHeight
            property int duration

            NumberAnimation {
                target: advanced
                property: "y"
                easing.type: Easing.InOutQuad
                duration: animation.duration
                to: -animation.targetHeight
            }

            NumberAnimation {
                target: advanced
                property: "height"
                easing.type: Easing.InOutQuad
                duration: animation.duration
                to: animation.targetHeight
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.highlightColor
            opacity: Theme.highlightBackgroundOpacity
        }

        Flow {
            id: advancedFlow
            anchors.fill: parent
            ScientificButton {
                text: calculation.functionText(Calculation.Sine)
                onClicked: calculation.sine()
            }
            ScientificButton {
                text: calculation.functionText(Calculation.Cosine)
                onClicked: calculation.cosine()
            }
            ScientificButton {
                text: calculation.functionText(Calculation.Tangent)
                onClicked: calculation.tangent()
            }
            ScientificButton {
                text: calculation.functionText(Calculation.Logarithm)
                onClicked: calculation.logarithm()
            }
            ScientificButton {
                text: calculation.functionText(Calculation.LogarithmBase10)
                onClicked: calculation.logarithmBase10()
            }
            ScientificButton {
                text: calculation.functionText(Calculation.Factorial)
                onClicked: calculation.factorial()
            }
            ScientificButton {
                text: calculation.constantText(Calculation.Pi)
                onClicked: calculation.setConstant(Calculation.Pi)
            }
            ScientificButton {
                text: calculation.constantText(Calculation.E)
                onClicked: calculation.setConstant(Calculation.E)
            }
            ScientificButton {
                text: calculation.symbolText(Calculation.Power)
                onClicked: calculation.power()
            }
            ScientificButton {
                text: calculation.symbolText(Calculation.OpenBracket)
                onClicked: calculation.openBracket()
            }
            ScientificButton {
                text: calculation.symbolText(Calculation.CloseBracket)
                onClicked: calculation.closeBracket()
            }
            ScientificButton {
                text: calculation.functionText(Calculation.SquareRoot)
                onClicked: calculation.squareRoot()
            }
        }

        function animate() {
            animation.targetHeight = open ? maximumHeight : 0
            animation.duration = 150 * Math.abs(animation.targetHeight - height) / maximumHeight
            animation.start()
        }
    }

    Image {
        id: handleTopHalf
        anchors { horizontalCenter: advanced.horizontalCenter; bottom: advanced.top }
        visible: calculatorPage.isPortrait
        source: "image://theme/graphic-edge-swipe-handle-top"
    }

    Image {
        anchors { horizontalCenter: advanced.horizontalCenter; top: advanced.top }
        visible: calculatorPage.isPortrait
        source: "image://theme/graphic-edge-swipe-handle-bottom"
    }

    Item {
        id: operations

        anchors.top: parent.top
        anchors.right: centerPlaceholder.right
        width: operationsColumn.width
        height: parent.height

        Rectangle {
            anchors.fill: parent
            color: Theme.highlightColor
            opacity: Theme.highlightBackgroundOpacity
        }

        Column {
            id: operationsColumn
            anchors.horizontalCenter: parent.horizontalCenter

            Row {
                AdvancedButton {
                    id: pasteKey
                    active: Clipboard.hasText
                    Image {
                        anchors { centerIn: parent; verticalCenterOffset: -Theme.paddingSmall }
                        opacity: pasteKey.active ? 1.0 : Theme.opacityLow
                        source: "image://theme/icon-m-clipboard?" + (pasteKey.highlighted ? Theme.highlightColor : Theme.primaryColor)
                    }
                    onClicked: active && calculation.paste()
                }
                AdvancedButton {
                    id: backspaceKey
                    Image {
                        anchors.centerIn: parent
                        source: "image://theme/icon-m-backspace?" + (backspaceKey.highlighted ? Theme.highlightColor : Theme.primaryColor)
                    }
                    onClicked: calculation.backspace()
                }
            }
            Row {
                OperationButton {
                    text: calculation.symbolText(Calculation.Divide)
                    onClicked: calculation.divide()
                }
                OperationButton {
                    text: calculation.symbolText(Calculation.Multiply)
                    onClicked: calculation.multiply()
                }
            }
            Row {
                OperationButton {
                    text: calculation.symbolText(Calculation.Add)
                    onClicked: calculation.add()
                }
                OperationButton {
                    text: calculation.symbolText(Calculation.Subtract)
                    onClicked: calculation.subtract()
                }
            }
            Row {
                OperationButton {
                    text: "C"
                    onClicked: calculatorPanel.clear()
                }
                OperationButton {
                    text: "="
                    onClicked: calculation.calculate()

                    Rectangle {
                        z: -1
                        opacity: Theme.highlightBackgroundOpacity
                        anchors.fill: parent
                        color: Theme.highlightColor
                    }
                }
            }
        }
    }

    Item {
        id: middlePlaceholder // empty space between two panels
        height: 1
        anchors.left: advanced.right
        anchors.right: operations.left
    }

    Item {
        id: centerPlaceholder // combination of numbers and basic operations centered
        height: 1
        width: numericColumn.width + operations.width
        anchors.horizontalCenter: parent.horizontalCenter
    }


    Column {
        id: numericColumn

        anchors.top: parent.top
        anchors.left: centerPlaceholder.left

        Row {
            Repeater {
                model: 3
                CalculatorButton {
                    text: (7 + index).toLocaleString()
                    onClicked: calculation.insert(text)
                }
            }
        }
        Row {
            Repeater {
                model: 3
                CalculatorButton {
                    text: (4 + index).toLocaleString()
                    onClicked: calculation.insert(text)
                }
            }
        }
        Row {
            Repeater {
                model: 3
                CalculatorButton {
                    text: (1 + index).toLocaleString()
                    onClicked: calculation.insert(text)
                }
            }
        }
        Row {
            CalculatorButton {
                text: (0).toLocaleString()
                onClicked: calculation.insert(text)
            }
            CalculatorButton {
                text: Qt.locale().decimalPoint
                onClicked: calculation.insert(text)
            }
            CalculatorButton {
                font.pixelSize: Theme.fontSizeLarge
                text: "±"
                onClicked: calculation.changeSign()
            }
        }
    }
}
