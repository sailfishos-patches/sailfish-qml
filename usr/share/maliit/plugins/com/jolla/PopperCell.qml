// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.keyboard 1.0

SilicaItem {
    id: popperCell
    width: geometry.accentPopperCellWidth
    height: geometry.popperHeight

    property bool active
    property alias character: textItem.text
    property alias textVisible: textItem.visible

    Label {
        id: textItem
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        // wider than parent so text fitting allows to use full popper area on single key mode
        width: geometry.popperWidth - Theme.paddingSmall
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: popperCell.active ? popperCell.palette.primaryColor
                                 : popperCell.palette.secondaryColor
        font.family: Theme.fontFamily
        font.pixelSize: geometry.popperFontSize
        // emoji are already bold enough by such, and qtquick would break the rendering.
        font.bold: popperCell.active && !KeyboardSupport.isEmoji(character)
        fontSizeMode: Text.Fit
    }
}
