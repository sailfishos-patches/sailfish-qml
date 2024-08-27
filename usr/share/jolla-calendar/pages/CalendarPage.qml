import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root

    objectName: "CalendarPage" // Used in DbusInvoker.qml

    function addEvent() {
        var now = new Date
        var d = tabHeader.date

        if (now.getHours() < 23 && now.getMinutes() > 0) {
            d.setHours(now.getHours() + 1)
        }

        d.setMinutes(0)
        d.setSeconds(0)

        pageStack.animatorPush("EventEditPage.qml", { defaultDate: d })
    }

    function gotoDate(date) {
        if (view.item) {
            view.item.gotoDate(date)
        }
    }

    TabHeader {
        id: tabHeader
        width: parent ? parent.width : root.width
        title: view.item ? view.item.title : ""
        description: view.item ? view.item.description : ""
        date: view.item ? view.item.date : new Date
        model: ListModel {
            ListElement {
                icon: "image://theme/icon-m-month-view"
                view: "MonthView.qml"
            }
            ListElement {
                icon: "image://theme/icon-m-week-view"
                view: "WeekView.qml"
            }
            ListElement {
                icon: "image://theme/icon-m-day-view"
                view: "DayView.qml"
            }
        }
    }

    Item {
        id: view
        property Item item
        property string source: tabHeader.currentView
        property var _cache

        anchors.fill: parent

        onSourceChanged: {
            if (_cache === undefined) {
                // Cannot assign ': []' to _cache otherwise the assignation
                // may run after the source changed signal on initialisation
                _cache = []
            }
            var currentDate = tabHeader.date
            if (item) {
                item.visible = false
                item.detachHeader()
            }
            if (source in _cache) {
                item = _cache[source]
            } else {
                var component = Qt.createComponent(source)
                if (component.status == Component.Error) console.warn(component.errorString())
                item = component.createObject(view, {})
                item.anchors.fill = view
                _cache[source] = item
            }
            item.gotoDate(currentDate)
            item.attachHeader(tabHeader)
            item.visible = true
        }

        Binding {
            target: pullDownMenu
            property: "flickable"
            value: view.item.flickable
        }
    }

    PullDownMenu {
        id: pullDownMenu
        busy: syncHelper.synchronizing

        MenuItem {
            //% "Sync"
            text: qsTrId("calendar-me-sync")
            onClicked: app.syncHelper.triggerRefresh()
        }
        MenuItem {
            //% "Settings"
            text: qsTrId("calendar-me-settings")
            onClicked: pageStack.animatorPush("SettingsPage.qml")
        }
        MenuItem {
            //% "Search"
            text: qsTrId("calendar-me-search")
            onClicked: pageStack.animatorPush("SearchPage.qml")
        }
        MenuItem {
            //% "Go to today"
            text: qsTrId("calendar-me-go_to_today")
            onClicked: root.gotoDate(new Date)
        }
        /* Disabled for now
        MenuItem {
            //% "Show agenda"
            text: qsTrId("calendar-me-show_agenda")
            onClicked: pageStack.animatorPush("AgendaPage.qml", {date: datePicker.date})
        }
        */
        MenuItem {
            //% "New event"
            text: qsTrId("calendar-me-new_event")
            onClicked: root.addEvent()
        }

        _inactivePosition: flickable.pullDownMenuOrigin !== undefined
            ? flickable.pullDownMenuOrigin
            : Math.round(flickable.originY - (_inactiveHeight + spacing))
        y: flickable.pullDownMenuOrigin !== undefined
            ? Math.max(flickable.contentY, flickable.pullDownMenuOrigin) - height
            : flickable.originY - height
    }
}
