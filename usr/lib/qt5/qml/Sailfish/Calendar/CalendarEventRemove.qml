/****************************************************************************
**
** Copyright (C) 2015 - 2019 Jolla Ltd.
** Copyright (C) 2020 - 2021 Open Mobile Platform LLC.
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    spacing: Theme.paddingMedium
    property bool readOnly

    signal eventRemovePressed

    Row {
        spacing: Theme.paddingMedium
        width: parent.width - 2 * Theme.horizontalPageMargin
        x: Theme.horizontalPageMargin

        Image {
            id: cancelIcon
            anchors.top: cancelText.lineCount > 1 ? parent.top : undefined
            source: "image://theme/icon-m-calendar-cancelled"
        }

        Label {
            id: cancelText
            width: parent.width - cancelIcon.width - spacing
            height: contentHeight
            anchors.top: lineCount > 1 ? parent.top : undefined
            anchors.verticalCenter: lineCount > 1 ? undefined : cancelIcon.verticalCenter
            color: Theme.highlightColor
            wrapMode: Text.Wrap
            //% "This event has been cancelled"
            text: qsTrId("sailfish_calendar-la-event_cancelled")
        }
    }

    Button {
        visible: !readOnly
        width: Math.min(parent.width - 2 * Theme.horizontalPageMargin, implicitWidth)
        anchors.horizontalCenter: parent.horizontalCenter
        //% "Remove from calendar"
        text: qsTrId("sailfish_calendar-la-event_cancelled_remove")
        onClicked: eventRemovePressed()
    }
}
