import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Calculator 1.0
import "pages"

ApplicationWindow {
    id: calculator

    _defaultLabelFormat: Text.PlainText

    property Calculation activeCalculation
    property Component calculationComponent: Component { Calculation {}}
    property real squareWidth: Screen.width / (Screen.sizeCategory > Screen.Medium ? 7 : 5)

    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All

    function formatResult(value) {
        if (value === "nan") {
            //% "NaN"
            return qsTrId("calculator-la-not_a_number")
        }
        return value
    }

    ListModel {
        id: calculations

        function newCalculation() {
            var calculation = calculationComponent.createObject(calculator)
            insert(0, {"calculation": calculation})
            return calculation
        }

        function clear() {
            if (count > 0) {
                while (count > 0) {
                    get(0).calculation.destroy()
                    remove(0)
                }
                Calculator.reset()
            }

            activeCalculation = newCalculation()
        }

        Component.onCompleted: clear()
    }

    Connections {
        target: activeCalculation
        onCompleted: activeCalculation = calculations.newCalculation()
    }

    initialPage: Component { CalculatorPage {} }
    cover: Qt.resolvedUrl("cover/CalculatorCover.qml")
}
