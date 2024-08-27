/*
 * Copyright (c) 2021 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    Label {
        x: Theme.horizontalPageMargin
        width: parent.width - 2*x
        wrapMode: Text.Wrap

        //% "Copying data failed. Aborting encryption"
        text: qsTrId("settings_encryption-la-copy-failed")
        color: Theme.errorColor

    }
}
