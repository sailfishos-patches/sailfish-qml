// Copyright (C) 2019 Jolla Ltd.
// Contact: Andrew den Exter <andrew.den.exter@jollamobile.com>

import QtQuick 2.6
import Sailfish.Silica 1.0

SilicaListView {
    id: view

    property bool canRemove
    property bool showRemoveButton
    property InputHandler handler

    signal predictionsChanged()

    anchors.fill: parent
    boundsBehavior: !keyboard.expandedPaste && Clipboard.hasText ? Flickable.DragOverBounds : Flickable.StopAtBounds

    onDraggingChanged: {
        if (!dragging && !keyboard.expandedPaste && contentX < -(headerItem.width + Theme.paddingLarge)) {
            keyboard.expandedPaste = true
            positionViewAtBeginning()
        }
    }

    onCanRemoveChanged: {
        if (!canRemove) {
            showRemoveButton = false
        }
    }

    onShowRemoveButtonChanged: {
        if (!showRemoveButton) {
            view.currentIndex = -1
        }
    }
}
