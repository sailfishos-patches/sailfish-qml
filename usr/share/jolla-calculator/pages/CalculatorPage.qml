import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: calculatorPage
    CalculationsListView {
        id: calculationsListView
        clip: true
        anchors {
            top: parent.top
            bottom: calculatorPanel.top
            bottomMargin: calculatorPanel.contentY
            right: parent.right
            left: parent.left
        }

        // view autoscroll implementation
        property real equationY
        property real equationHeight

        // store the position of focused equation as delegates
        // can get destroyed when moved outside the view port
        function calculateAutoScrollPosition() {
            if (focusEquation) {
                equationY = contentItem.mapFromItem(focusEquation, 0, 0).y
                equationHeight = focusEquation.height
            }
        }

        function autoScroll() {
            var _equationY = mapFromItem(contentItem, 0, equationY).y
            var scrollMargin = 0
            var animate = false
            if (_equationY < scrollMargin) {
                animate = true
                autoScrollAnimation.to = Math.max(originY, contentY + _equationY - scrollMargin)
            } else if (_equationY + equationHeight + scrollMargin > height) {
                animate = true
                autoScrollAnimation.to = Math.min(originY + contentHeight - height,
                                                  contentY + _equationY + equationHeight + scrollMargin - height)
            }
            if (animate && !moving) {
                autoScrollAnimation.restart()
            }
        }

        onFocusEquationChanged: positionTimer.restart()
        Component.onCompleted: positionTimer.restart()
        onMovingChanged: if (moving) autoScrollAnimation.stop()

        Timer {
            id: positionTimer
            interval: 10
            onTriggered: parent.calculateAutoScrollPosition()
        }
        NumberAnimation {
            id: autoScrollAnimation
            easing.type: Easing.InOutQuad
            target: calculationsListView
            property: "contentY"
            duration: 400
        }
    }
    ScientificCalculatorHint {
        width: parent.width
        anchors {
            top: parent.top
            bottom: calculatorPanel.top
        }
    }
    CalculatorPanel {
        id: calculatorPanel

        onButtonClicked: calculationsListView.autoScroll()
        onMenuClosed: positionTimer.restart()
        onClear: calculations.clear()

        calculation: activeCalculation
        anchors.bottom: parent.bottom
    }
}
