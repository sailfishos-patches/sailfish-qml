/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Raine Makelainen <raine.makelainen@jolla.com>
**
****************************************************************************/

import QtQuick 2.2

Rectangle {
    id: root

    property alias text: label.text

    signal clicked

    width: 70; height: 30
    color: "#d0b0c4de"
    radius: 5
    border.color: "black"
    anchors.right: parent.right
    anchors.rightMargin: 10
    y: 10
    Text {
        id: label
        anchors.centerIn: parent
        font.pixelSize: 20
    }
    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
