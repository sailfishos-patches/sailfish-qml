/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    onRejected: Qt.quit()

    objectName: "disclaimer"

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: parent.width

            CsdDialogHeader {
                //% "Disclaimer"
                title: qsTrId("csd-he-disclaimer")
                //% "Accept"
                acceptText: qsTrId("csd-he-accept")
            }

            Label {
                x: Theme.paddingLarge
                width: parent.width - 2*Theme.paddingLarge

                text: disclaimerText
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
            }
        }
    }
}
