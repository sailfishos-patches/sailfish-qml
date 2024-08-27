import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: calculatorButton

    property string text
    property alias font: label.font
    property bool active: true

    implicitWidth: squareWidth

    highlighted: active && down
    _showPress: highlighted
    _pressEffectDelay: false
    height: implicitWidth * (pageStack.currentPage.isLandscape ? 0.75 : 1.0)
    width: implicitWidth

    onPressed: {
        if (active && _feedbackEffect) {
            _feedbackEffect.play()
        }
    }
    onClicked: if (active && calculatorPanel) calculatorPanel.buttonClicked()

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
