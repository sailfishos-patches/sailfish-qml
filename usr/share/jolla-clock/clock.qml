import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.alarms 1.0
import org.nemomobile.dbus 2.0
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

        function activateWindow(arg) {
            mainWindow.activate()
        }
    }
}

