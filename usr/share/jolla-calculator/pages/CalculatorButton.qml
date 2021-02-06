import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: calculatorButton

    property string text
    property bool highlighted: down
    property alias font: label.font

    implicitWidth: squareWidth

    _pressEffectDelay: false
    height: implicitWidth * (pageStack.currentPage.isLandscape ? 0.75 : 1.0)
    width: implicitWidth

    onPressed: {
        if (_feedbackEffect) {
            _feedbackEffect.play()
        }
    }
    onClicked: if (calculatorPanel) calculatorPanel.buttonClicked()

    Label {
        id: label
        font {
            family: Theme.fontFamilyHeading
            pixelSize: Theme.fontSizeExtraLarge
        }
        anchors.centerIn: parent
        text: calculatorButton.text
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
    }
}
