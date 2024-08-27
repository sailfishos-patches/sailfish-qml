import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Nemo.DBus 2.0
import Calendar.syncHelper 1.0
import "pages"

ApplicationWindow {
    id: app

    initialPage: Component { CalendarPage { } }
    cover: Qt.resolvedUrl("cover/CalendarCover.qml")
    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    function showMainPage(operationType) {
        var first = pageStack.currentPage
        var temp = pageStack.previousPage(pageStack.currentPage)
        while (temp) {
            first = temp
            temp = pageStack.previousPage(temp)
        }

        pageStack.pop(first, operationType)
    }

    function qsTrIdStrings()
    {
        //% "Show agenda"
        QT_TRID_NOOP("calendar-me-show_agenda")
    }

    DbusInvoker {}

    Timer {
        id: requestActive
        property int count: 0
        interval: 100
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            ++count
            if (Qt.application.active || count >= 10) {
                stop()
                count = 0
            } else {
                app.activate()
            }
        }
    }

    property SyncHelper syncHelper: SyncHelper { }
    Component.onCompleted: {
        //TODO: enable FB sync on startup when delta sync is supported! JB#12118
        syncHelper.triggerUpdateImmediately()
    }
}

