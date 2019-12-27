/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

PageHeader {
    id: root

    property alias folderName: folderText.text
    property int count
    property string errorText

    title: count > 0 ? count.toLocaleString() : ""
    height: Math.max(_preferredHeight, _titleItem.y + _titleItem.height + ((errorText.length > 0) ? errorItem.height : 0) + Theme.paddingMedium)

    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

    Label {
        id: folderText
        anchors {
            left: parent.left
            leftMargin: parent.leftMargin
            right: root._titleItem.left
            rightMargin: title != "" ? Theme.paddingSmall : 0
            verticalCenter: root._titleItem.verticalCenter
        }
        truncationMode: TruncationMode.Fade
        horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignRight

        font: root._titleItem.font
    }

    // The styling matches the description field taken from
    // sailfish-silica/components/private/PageHeaderDescription.qml
    // It's reimplemented here so that the opacity can be animated
    Label {
        id: errorItem
        opacity: ((root.errorText.length > 0) ? 1 : 0)
        visible: opacity > 0
        Behavior on opacity { FadeAnimation {} }

        width: parent.width - parent.leftMargin - parent.rightMargin
        anchors {
            top: parent._titleItem.bottom
            right: parent.right
            rightMargin: parent.rightMargin
        }
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.secondaryHighlightColor
        horizontalAlignment: Text.AlignRight
        truncationMode: TruncationMode.Fade
    }

    onErrorTextChanged: {
        if (errorText.length > 0) {
            errorItem.text = errorText
        }
    }
}
