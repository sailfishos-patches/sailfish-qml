/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

TestCaseBaseItem {
    Label {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * x
        wrapMode: Text.Wrap
        text: displayName + (testStatusVisible ? ": " + testStatus : "")
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
    }
}
