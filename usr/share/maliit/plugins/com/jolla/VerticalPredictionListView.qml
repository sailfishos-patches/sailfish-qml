// Copyright (C) 2019 Jolla Ltd.
// Contact: Andrew den Exter <andrew.den.exter@jollamobile.com>

import QtQuick 2.6
import Sailfish.Silica 1.0

PredictionListView {
    id: view

    property real _buttonMargin: showRemoveButton ? Theme.itemSizeExtraSmall : 0

    Behavior on _buttonMargin { NumberAnimation { duration: 100 } }

    clip: true

    Component.onCompleted: {
        if (Clipboard.hasText) {
            stateChange.restart()
        }
    }

    onPredictionsChanged: {
        if (!stateChange.running) {
            view.positionViewAtIndex(0, ListView.Beginning)
        }
    }

    header: PasteButtonVertical {
        visible: Clipboard.hasText
        width: view.width
        height: visible ? geometry.keyHeightLandscape : 0
        popupParent: view.parent
        popupAnchor: 2 // center

        onClicked: view.handler.paste(Clipboard.text)
    }

    delegate: BackgroundItem {
        id: delegate

        width: parent.width
        height: geometry.keyHeightLandscape // assuming landscape!

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
            width: delegate.width  - view._buttonMargin
            height: delegate.height

            text: view.handler.formatText(model.text)
            font.pixelSize: Theme.fontSizeSmall

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter

            elide: Text.ElideRight
            textFormat: Text.StyledText
            fontSizeMode: Text.HorizontalFit
        }

        IconButton {
            id: removeButton
            x: delegate.width - width
            width: Theme.itemSizeExtraSmall
            height: delegate.height

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
            verticalList.positionViewAtBeginning()
            stateChange.restart()
        }
    }
    Connections {
        target: MInputMethodQuick
        onFocusTargetChanged: {
            verticalList.positionViewAtBeginning()
            stateChange.restart()
        }
    }

    Timer {
        id: stateChange
        interval: 1000
    }
}
