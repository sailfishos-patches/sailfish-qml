/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import Nfc 1.0

CheckLabel {
    checked: nfc.docked && !nfc.ready
    //% "NFC"
    text: qsTrId("csd-la-nfc")
    Nfc { id: nfc }
}
