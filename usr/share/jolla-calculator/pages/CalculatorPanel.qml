import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calculator 1.0

PanelBackground {
    id: calculatorPanel

    property Calculation calculation
    property QtObject _feedbackEffect

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
        when: pageStack.currentPage.isLandscape

        PropertyChanges {
            target: advanced
            visible: true
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

        visible: false
        //width: advancedColumn.width + 2*Theme.horizontalPageMargin
        width: advancedColumn.width
        height: parent.height

        Rectangle {
            anchors.fill: parent
            color: Theme.highlightColor
            opacity: Theme.highlightBackgroundOpacity
        }

        Column {
            id: advancedColumn
            anchors.horizontalCenter: parent.horizontalCenter

            Row {
                AdvancedButton {
                    text: calculation.functionText(Calculation.Sine)
                    onClicked: calculation.sine()
                }
                AdvancedButton {
                    text: calculation.functionText(Calculation.Cosine)
                    onClicked: calculation.cosine()
                }
                AdvancedButton {
                    text: calculation.functionText(Calculation.Tangent)
                    onClicked: calculation.tangent()
                }
            }
            Row {
                AdvancedButton {
                    text: calculation.functionText(Calculation.Logarithm)
                    onClicked: calculation.logarithm()
                }
                AdvancedButton {
                    text: calculation.functionText(Calculation.LogarithmBase10)
                    onClicked: calculation.logarithmBase10()
                }
                AdvancedButton {
                    text: calculation.functionText(Calculation.Factorial)
                    onClicked: calculation.factorial()
                }
            }
            Row {
                AdvancedButton {
                    text: calculation.constantText(Calculation.Pi)
                    onClicked: calculation.setConstant(Calculation.Pi)
                }
                AdvancedButton {
                    text: calculation.constantText(Calculation.E)
                    onClicked: calculation.setConstant(Calculation.E)
                }
                AdvancedButton {
                    text: calculation.symbolText(Calculation.Power)
                    onClicked: calculation.power()
                }
            }
            Row {
                AdvancedButton {
                    text: calculation.symbolText(Calculation.OpenBracket)
                    onClicked: calculation.openBracket()
                }
                AdvancedButton {
                    text: calculation.symbolText(Calculation.CloseBracket)
                    onClicked: calculation.closeBracket()
                }
                AdvancedButton {
                    text: calculation.functionText(Calculation.SquareRoot)
                    onClicked: calculation.squareRoot()
                }
            }
        }
    }

    Item {
        id: operations

        anchors.right: centerPlaceholder.right
        //width: operationsColumn.width + (_landscape ? 2*Theme.horizontalPageMargin : 0)
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
                    enabled: Clipboard.hasText
                    Image {
                        anchors { centerIn: parent; verticalCenterOffset: -Theme.paddingSmall }
                        opacity: pasteKey.enabled ? 1.0 : Theme.opacityLow
                        source: "image://theme/icon-m-clipboard?" + (pasteKey.pressed ? Theme.highlightColor : Theme.primaryColor)
                    }
                    onClicked: calculation.paste()
                }
                AdvancedButton {
                    id: backspaceKey
                    Image {
                        anchors.centerIn: parent
                        source: "image://theme/icon-m-backspace?" + (backspaceKey.pressed ? Theme.highlightColor : Theme.primaryColor)
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
