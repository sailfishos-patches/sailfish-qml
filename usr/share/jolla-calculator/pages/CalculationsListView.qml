import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calculator 1.0

SilicaListView {
    id: calculationsListView

    property bool coverMode
    property Item focusEquation
    property real layoutMultiplier: coverMode ? 0.5 : (pageStack.currentPage.isLandscape ? 0.75 : 1.0)
    property int primaryFontSize: coverMode ? Theme.fontSizeMedium
                                            : (pageStack.currentPage.isLandscape ? Theme.fontSizeLarge : Theme.fontSizeExtraLarge)
    property int secondaryFontSize: coverMode ? Theme.fontSizeExtraSmall
                                              : (pageStack.currentPage.isLandscape ? Theme.fontSizeMedium : Theme.fontSizeLarge)

    model: calculations
    verticalLayoutDirection: ListView.BottomToTop
    quickScroll: false

    delegate: ListItem {
        id: listItem
        contentHeight: equation.height
        menu: Component {
            ContextMenu {
                MenuItem {
                    //% "Copy"
                    text: qsTrId("calculator-me-copy")
                    onClicked: Clipboard.text = calculation.result.valueText
                }
            }
        }
        Flickable {
            id: equation

            width: calculationsListView.width

            // The implicit height of fraction delegate can grow over the design spec
            // e.g. if user has chosen huge system-wide fonts in Display settings
            height: Math.max(layoutMultiplier * 1.5 * squareWidth, fractionField.height + Theme.paddingSmall)

            flickableDirection: Flickable.HorizontalFlick
            contentWidth: equationRow.width + Theme.paddingLarge
            transform: Scale { origin.x: equation.width/2; xScale: -1}
            boundsBehavior: Flickable.StopAtBounds

            Component.onCompleted: {
                calculation.operationMadeToEmptyCalculation.connect(function() {
                    if (calculations.count > 1) {
                        calculation.focusField.link(calculations.get(1).calculation.result)
                    }
                })
            }

            ListView.onAdd: AddAnimation { target: equation }

            Row {
                id: equationRow
                transform: Scale { origin.x: equationRow.width/2; xScale: -1}
                anchors.verticalCenter: parent.verticalCenter

                function highlightItemAt(index) {
                    activeCalculation = calculation
                    activeCalculation.currentIndex = index
                }

                Repeater {
                    model: calculation
                    Loader {
                        property bool activeItem: calculation == activeCalculation && calculation.currentIndex == index

                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        sourceComponent: type == Calculation.Field ? fieldComponent
                                                                   : (type == Calculation.Function ? functionComponent : operationComponent)
                        Component {
                            id: fieldComponent
                            FieldItem {
                                id: fieldItem

                                focused: activeItem
                                linkText: field.linkText
                                fractionBar: field.fraction
                                numerator: field.numerator
                                denominator: field.denominator
                                coverMode: calculationsListView.coverMode
                                anchors.verticalCenter: parent.verticalCenter

                                onClicked: equationRow.highlightItemAt(index)

                                Binding {
                                    // focus equation is the equation, which has the focused field
                                    when: fieldItem.focused && !calculationsListView.coverMode
                                    target: calculationsListView
                                    property: "focusEquation"
                                    value: equation
                                }
                            }
                        }
                        Component {
                            id: operationComponent
                            OperationItem {
                                coverMode: calculationsListView.coverMode
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.text
                            }
                        }
                        Component {
                            id: functionComponent
                            FunctionItem {
                                coverMode: calculationsListView.coverMode
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.text
                            }
                        }
                    }
                }

                Row {
                    id: resultRow

                    visible: calculation.result.valid
                    anchors.verticalCenter: parent.verticalCenter
                    OperationItem {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "="
                        coverMode: calculationsListView.coverMode
                    }
                    ResultItem {
                        anchors.verticalCenter: parent.verticalCenter
                        text: calculation.result.valueText
                        linkText: calculation.result.linkText
                        coverMode: calculationsListView.coverMode

                        onClicked: {
                            if (activeCalculation != calculation) {
                                activeCalculation.focusField.link(calculation.result)
                            }
                        }
                        onPressAndHold: listItem.openMenu()
                    }
                }
            }
        }
    }

    FieldItem {
        id: fractionField
        visible: false
        fractionBar: true
        coverMode: calculationsListView.coverMode
        numerator: "1"
        denominator: "2"
    }
    VerticalScrollDecorator {}
}
