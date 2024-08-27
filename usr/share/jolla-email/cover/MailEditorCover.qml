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
        id: toLabel

        y: Theme.paddingLarge
        //: 'To: ' recipient cover label
        //% "To: %1"
        text: qsTrId("jolla-email-la-to_cover").arg(app.editorTo)
        font.pixelSize: Theme.fontSizeSmall
        maximumLineCount: 2
    }
    CoverLabel {
        property int lineHeight: toLabel.height/toLabel.lineCount

        text: app.editorBody
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeSmall
        maximumLineCount: Math.round(height/lineHeight)
        anchors {
            top: toLabel.bottom
            bottom: parent.bottom
            topMargin: Theme.paddingLarge
            bottomMargin: Theme.paddingMedium
        }
    }
}
