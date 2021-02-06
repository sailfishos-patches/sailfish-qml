// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaItem {
    id: selectionCell

    property int index
    property bool active: popup.activeCell === index
    property alias text: textItem.text

    width: textItem.paintedWidth + geometry.languageSelectionCellMargin * 2
    height: Theme.itemSizeSmall

    Label {
        id: textItem
        anchors.centerIn: parent
        color: selectionCell.active ? selectionCell.palette.primaryColor
                                    : selectionCell.palette.secondaryColor
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeMedium
        font.bold: selectionCell.active
    }

    Rectangle {
        color: selectionCell.palette.primaryColor
        height: Math.round(Theme.dp(2))
        width: textItem.paintedWidth
        anchors.top: textItem.bottom
        anchors.horizontalCenter: textItem.horizontalCenter
        visible: selectionCell.active
    }
}
