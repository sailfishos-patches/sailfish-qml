/*
 * Copyright (c) 2017 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.devicelock 1.0

Dialog {
    id: warningDialog

    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        DialogHeader {
            dialog: warningDialog

            //% "No"
            cancelText: qsTrId("startupwizard-la-security_code_warning_no")
            //% "Yes"
            acceptText: qsTrId("startupwizard-la-security_code_warning_yes")
        }

        Label {
            x: Theme.horizontalPageMargin
            color: Theme.highlightColor
            width: parent.width - Theme.horizontalPageMargin * 2
            wrapMode: Text.Wrap
            font {
                family: Theme.fontFamilyHeading
                pixelSize: Theme.fontSizeExtraLarge
            }

            //% "Do you really want to skip setting a security code?"
            text: qsTrId("startupwizard-la-recommended_security_code")
        }

        Label {
            id: warningLabel

            x: Theme.horizontalPageMargin
            width: parent.width - Theme.horizontalPageMargin * 2
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.highlightColor
            //% "Without a security code you won't be able to prevent others from using this device if it gets stolen or lost."
            text: qsTrId("startupwizard-la-recommended_security_code_description")
            wrapMode: Text.Wrap
        }
    }
}
