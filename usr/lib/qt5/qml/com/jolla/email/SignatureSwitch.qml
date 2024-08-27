/*
 * Copyright (c) 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1

TextSwitch {
    id: root
    property var protocol
    property bool error
    //: Numerically sign email
    //% "Sign email"
    text: qsTrId("jolla-email-la-sign_email")
    description: {
        if (error) {
            //% "Signature failed"
            return qsTrId("jolla-email-la-crypto_signature_failure")
        } else {
            switch (protocol)
            {
            case EmailMessage.OpenPGP:
                //% "PGP"
                return qsTrId("jolla-email-la-crypto_signature_pgp")
            case EmailMessage.SecureMIME:
                //% "S/MIME"
                return qsTrId("jolla-email-la-crypto_signature_smime")
            default:
                //% "Unknown type"
                return qsTrId("jolla-email-la-crypto_signature_unknown")
            }
        }
    }
    onCheckedChanged: if (!checked) error = false
    Rectangle {
        anchors.fill: parent
        opacity: root.error ? Theme.opacityHigh : 0.0
        color: Theme.errorColor
        Behavior on opacity { FadeAnimation{} }
        z: -1
    }
}
