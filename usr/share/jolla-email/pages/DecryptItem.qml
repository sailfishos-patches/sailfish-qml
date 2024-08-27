/*
 * Copyright (c) 2023 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1

// Can become a BackgroundItem when decrypt capability will be available
Item {
    property EmailMessage email
    readonly property int encryptionStatus: email ? email.encryptionStatus : EmailMessage.NoDigitalEncryption

    height: Theme.itemSizeExtraSmall
    visible: encryptionStatus != EmailMessage.NoDigitalEncryption

    Icon {
        id: icon
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        source: "image://theme/icon-m-device-lock"
    }

    Label {
        anchors {
            left: icon.right
            right: parent.right
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.horizontalPageMargin
        }
        height: parent.height

        //% "Encrypted content"
        text: qsTrId("jolla-email-la-encrypted_content")
        font.pixelSize: Theme.fontSizeSmall
        verticalAlignment: Text.AlignVCenter
        truncationMode: TruncationMode.Fade
    }
}
