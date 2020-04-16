// Copyright (C) 2019 Jolla Ltd.
// Contact: Andrew den Exter <andrew.den.exter@jollamobile.com>

import QtQuick 2.6
import Sailfish.Silica 1.0

PredictionListView {
    id: view

    property real _buttonMargin: showRemoveButton ? Theme.itemSizeExtraSmall : Theme.paddingLarge
    readonly property real _maximumLabelWidth: width - (2 * Theme.paddingLarge)

    orientation: ListView.Horizontal

    Behavior on _buttonMargin { NumberAnimation { id: marginAnimation; duration: 100 } }

    onPredictionsChanged: {
        view.positionViewAtBeginning()
    }

    header: PasteButton {
        onClicked: {
            view.handler.paste(Clipboard.text)
            keyboard.expandedPaste = false
        }
    }

    delegate: BackgroundItem {
        id: delegate

        width: Theme.paddingLarge + label.width + view._buttonMargin
        height: view.height

        clip: marginAnimation.running

        onClicked: {
            if (view.showRemoveButton) {
                view.showRemoveButton = false
            } else {
                view.handler.select(model.text, model.index)
            }
        }

        onPressAndHold: {
            if (view.canRemove && !view.showRemoveButton) {
                view.currentIndex = index
                delegate.HorizontalAutoScroll.keepVisible = Qt.binding(function() { return delegate.ListView.isCurrentItem })
                view.showRemoveButton = true
            } else {
                view.showRemoveButton = false
            }
        }

        Label {
            id: label

            x: Theme.paddingLarge
            width: Math.min(implicitWidth, view._maximumLabelWidth + Theme.paddingLarge - view._buttonMargin)
            height: delegate.height

            text: view.handler.formatText(model.text)
            font.pixelSize: Theme.fontSizeSmall

            verticalAlignment: Text.AlignVCenter

            truncationMode: TruncationMode.Fade
            textFormat: Text.StyledText

            color: highlighted ? Theme.highlightColor : Theme.primaryColor
        }

        IconButton {
            id: removeButton
            x: label.x + label.width
            height: delegate.height
            width: delegate.height

            icon.source: "image://theme/icon-m-input-remove"

            enabled: view.showRemoveButton

            opacity: view.showRemoveButton ? 1 : 0

            onClicked: view.handler.remove(model.text, model.index)

            Behavior on opacity { FadeAnimator { duration: 100 } }
        }
    }

    Connections {
        target: Clipboard
        onTextChanged: {
            if (Clipboard.hasText) {
                // need to have updated width before repositioning view
                positionerTimer.restart()
            }
        }
    }

    Timer {
        id: positionerTimer
        interval: 10
        onTriggered: view.positionViewAtBeginning()
    }
}
