/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0

VerificationCellular {
    //% "2G information"
    pageTitle: qsTrId("csd-he-2g_information")
    testTechnology: ["gsm", "edge"]
    requireAllModems: true
}
