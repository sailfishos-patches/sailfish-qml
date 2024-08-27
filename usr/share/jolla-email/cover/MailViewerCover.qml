/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    anchors.fill: parent

    CoverLabel {
        anchors {
            top: parent.top
            bottom: senderLabel.top
            topMargin: Theme.paddingLarge
            bottomMargin: Theme.paddingMedium
        }
        text: "\"" + app.viewerSubject + "\""
        color: Theme.primaryColor
        maximumLineCount: Math.round(height/lineHeight)
        property int lineHeight: senderLabel.height/senderLabel.lineCount
    }

    CoverLabel {
        id: senderLabel
        text: app.viewerSender
        maximumLineCount: 2
        anchors { bottom: parent.bottom; bottomMargin: Theme.paddingLarge }
    }
}
