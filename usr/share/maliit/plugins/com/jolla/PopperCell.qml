// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: popperCell
    width: geometry.accentPopperCellWidth
    height: geometry.popperHeight

    property bool active
    property alias character: textItem.text
    property alias textVisible: textItem.visible

    Text {
        id: textItem
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        // wider than parent so text fitting allows to use full popper area on single key mode
        width: geometry.popperWidth - Theme.paddingSmall
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: Theme.primaryColor
        opacity: popperCell.active ? 1 : .35
        font.family: Theme.fontFamily
        font.pixelSize: geometry.popperFontSize
        fontSizeMode: Text.Fit
    }
}
