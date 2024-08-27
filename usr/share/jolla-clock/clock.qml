/**
 * Copyright (c) 2012 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Alarms 1.0
import Nemo.DBus 2.0
import "pages"
import "cover"

ApplicationWindow {
    id: mainWindow

    property Item mainPage
    property bool stopwatchMode
    property ListModel stopwatch

    allowedOrientations: Screen.sizeCategory > Screen.Medium
                         ? defaultAllowedOrientations
                         : defaultAllowedOrientations & Orientation.PortraitMask
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    cover: ClockCover {}
    initialPage: Component {
        MainPage {
            id: mainPage

            Component.onCompleted: mainWindow.mainPage = mainPage
        }
    }

    AlarmsModel {
        id: alarmsModel
    }
    AlarmsModel {
        id: timersModel
        onlyCountdown: true
    }

    DBusAdaptor {
        service: "com.jolla.clock"
        path: "/"
        iface: "com.jolla.clock"

        function newAlarm() {
            pageStack.pop(mainPage, PageStackAction.Immediate)
            mainPage.newAlarm(PageStackAction.Immediate)
            mainWindow.activate()
        }

        function activateWindow(tabName) {
            mainPage.showTab(tabName)
            mainWindow.activate()
        }
    }
}

