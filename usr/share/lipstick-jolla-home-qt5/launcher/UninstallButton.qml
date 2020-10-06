/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.1
import Sailfish.Silica 1.0

Image {
    id: root
    readonly property bool down: uninstallArea.pressed && uninstallArea.containsMouse
    signal clicked()

    source: "image://theme/icon-s-clear-opaque-background?" + (Theme.colorScheme === Theme.LightOnDark
                                                               ? down ? Theme.highlightColor
                                                                      : Theme.primaryColor
                                                               : down ? Theme.highlightDimmerColor
                                                                      : Theme.highlightBackgroundColor)

    Behavior on opacity { FadeAnimation {} }

    Image {
        anchors.centerIn: parent
        source: "image://theme/icon-s-clear-opaque-cross?" + (Theme.colorScheme === Theme.LightOnDark
                                                              ? root.down ? Theme.highlightDimmerColor
                                                                          : Theme.highlightBackgroundColor
                                                              : root.down ? Theme.darkSecondaryColor
                                                                          : Theme.lightPrimaryColor)
    }

    MouseArea {
        id: uninstallArea
        objectName: "UninstallButton"
        anchors {
            fill: parent
            margins: -Theme.paddingSmall        // expand a little around the button
            bottomMargin: -Theme.paddingMedium  // Bottom has a bit bigger negative margin.
        }
        onClicked: root.clicked()
    }
}
