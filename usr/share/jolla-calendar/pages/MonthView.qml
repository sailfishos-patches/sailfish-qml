import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import org.nemomobile.calendar 1.0
import "Util.js" as Util

SilicaListView {
    id: view

    readonly property date date: headerItem ? headerItem.date : new Date
    readonly property string title: Util.capitalize(Format.formatDate(date, Formatter.MonthNameStandalone))
    readonly property string description: {
        var now = new Date
        return now.getFullYear() != date.getFullYear() ? date.getFullYear() : ""
    }
    property int _eventX: headerItem && Screen.sizeCategory <= Screen.Medium ? headerItem.x : 0
    property alias flickable: view

    property Item tabHeader
    function attachHeader(tabHeader) {
        if (tabHeader) {
            tabHeader.parent = headerItem
        }
        view.tabHeader = tabHeader
    }
    function detachHeader() {
        view.tabHeader = null
    }
    function gotoDate(date) {
        if (headerItem) {
            headerItem.gotoDate(date)
        }
    }

    header: Item {
        property int _tabHeight: view.tabHeader ? view.tabHeader.height : 0
        property date date: datePicker.date
        function gotoDate(date) {
            datePicker.date = date
        }

        x: isPortrait ? 0 : datePicker.width
        width: view.width - x
        height: {
            var h = _tabHeight
            if (isPortrait) {
                if (Screen.sizeCategory > Screen.Medium) {
                    h += Math.max(datePicker.height, additionalInformation.height)
                } else {
                    h += datePicker.height + additionalInformation.height
                }
            } else {
                h += additionalInformation.height
                if (Screen.sizeCategory > Screen.Medium) {
                    h = Math.max(datePicker.height, h)
                }
            }
            return h + Theme.paddingLarge
        }

        Connections {
            target: tabHeader
            onDateClicked: {
                var obj = pageStack.animatorPush(yearMonthDialog)
                obj.pageCompleted.connect(function(page) {
                    page.monthActivated.connect(function(month, year) {
                        var date = datePicker.date
                        date.setFullYear(year)
                        date.setMonth(month - 1)
                        datePicker.date = date
                        pageStack.pop()
                    })
                })
            }
        }

        Component {
            id: yearMonthDialog
            Page {
                signal monthActivated(int month, int year)
                Private.YearMonthMenu {
                    onMonthActivated: parent.monthActivated(month, year)
                }
            }
        }

        DatePickerPanel {
            id: datePicker
            anchors.right: isPortrait ? parent.right : parent.left
            anchors.top: isPortrait && tabHeader ? tabHeader.bottom : parent.top
            width: isPortrait ? view.width : (view.width*0.5)
        }

        Binding {
            target: agendaModel
            property: "startDate"
            value: datePicker.date
            when: !datePicker.viewMoving
        }

        Column {
            id: additionalInformation
            width: parent.width - Theme.horizontalPageMargin
            anchors.top: isPortrait && Screen.sizeCategory <= Screen.Medium
                ? datePicker.bottom : tabHeader ? tabHeader.bottom : parent.top

            Label {
                visible: Screen.sizeCategory > Screen.Medium
                anchors.right: parent.right
                font.pixelSize: Theme.fontSizeHuge * 4.5
                renderType: Text.NativeRendering
                text: date.getDate()
                color: Theme.highlightColor
                height: implicitHeight - 2 * Theme.paddingLarge
                Label {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    font.pixelSize: Theme.fontSizeHuge
                    text: Util.capitalize(Format.formatDate(date, Format.WeekdayNameStandalone))
                    color: Theme.highlightColor
                }
            }

            InfoLabel {
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
                text: datePicker.dstIndication
                visible: text.length > 0
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                height: implicitHeight + Theme.paddingLarge
            }
        }

        // Placeholder
        Item {
            width: parent.width
            height: view.height - y
            y: parent.height

            visible: view.count === 0 && !agendaModel.loading

            InfoLabel {
                y: parent.height / 3 - height / 2
                //% "Your schedule is free"
                text: qsTrId("calendar-me-schedule_is_free")
            }
        }
    }

    model: AgendaModel {
        id: agendaModel
        property bool loading: true
        onStartDateChanged: loading = true
        onUpdated: loading = false
    }

    delegate: DeletableListDelegate {
        // Update activeDay after the contents of agendaModel changes (after the initial update)
        // to prevent delegates from recalculating time labels before agendaModel responds to
        // changes in datePicker.date

        x: view._eventX + Theme.paddingSmall
        width: view.width - x

        Component.onCompleted: activeDay = agendaModel.startDate

        Connections {
            target: agendaModel
            onUpdated: activeDay = agendaModel.startDate
        }
    }

    VerticalScrollDecorator {}
}

