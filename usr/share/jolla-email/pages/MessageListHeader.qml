/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

PageHeader {
    id: root

    property alias folderName: folderText.text
    property int count
    property string errorText

    title: count > 0 ? count.toLocaleString() : ""
    titleColor: palette.highlightColor
    interactive: true   // don't wait until folder list is pushed to indicate the header is interactive
    highlighted: defaultHighlighted || folderMouseArea.containsMouse

    height: Math.max(_preferredHeight, _titleItem.y + _titleItem.height + ((errorText.length > 0) ? errorLabel.height : 0) + Theme.paddingMedium)

    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

    Label {
        id: folderText

        parent: root.extraContent

        x: parent.width - width
        y: Math.floor((root._preferredHeight - height) / 2)

        width: Math.min(implicitWidth, parent.width)

        rightPadding: root.title !== "" ? Theme.paddingMedium : 0

        truncationMode: TruncationMode.Fade

        font: root._titleItem.font
        color: highlighted ? palette.highlightColor : palette.primaryColor

        MouseArea {
            id: folderMouseArea

            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
            }
            width: parent.implicitWidth + Theme.paddingLarge
            height: root.height

            onClicked: pageStack.navigateForward()
        }
    }

    // The styling matches the description field taken from
    // sailfish-silica/components/private/PageHeaderDescription.qml
    // It's reimplemented here so that the opacity can be animated
    Item {
        id: errorItem

        x: root.leftMargin
        y: root._titleItem.y + root._titleItem.height
        width: root.width - root.leftMargin - root.rightMargin

        opacity: ((root.errorText.length > 0) ? 1 : 0)
        Behavior on opacity { FadeAnimation {} }

        Icon {
            id: errorIcon

            x: errorLabel.x - width - Theme.paddingSmall
            y: (errorLabel.height - height) / 2

            source: "image://theme/icon-s-warning"
            color: palette.secondaryHighlightColor
        }

        Label {
            id: errorLabel

            x: errorItem.width - width

            width: Math.min(implicitWidth, errorItem.width - errorIcon.width - Theme.paddingSmall)

            font.pixelSize: Theme.fontSizeSmall
            color: palette.secondaryHighlightColor
            horizontalAlignment: Text.AlignRight
            truncationMode: TruncationMode.Fade
        }
    }

    onErrorTextChanged: {
        if (errorText.length > 0) {
            errorLabel.text = errorText
        }
    }
}
