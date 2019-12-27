/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Label {
    property bool result

    font.bold: true
    color: result ? "green" : "red"
    text: result ?
              //% "Pass"
              qsTrId("csd-la-pass")
              //% "Fail"
            : qsTrId("csd-la-fail")
}
