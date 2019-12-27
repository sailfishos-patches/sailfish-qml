import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import org.nemomobile.time 1.0
import "Util.js" as Util

Page {
    id: root

    property bool initialLoadDone

    function addEvent() {
        var now = new Date
        var d = datePicker.date

        if (now.getHours() < 23 && now.getMinutes() > 0) {
            d.setHours(now.getHours() + 1)
        }

        d.setMinutes(0)
        d.setSeconds(0)

        pageStack.animatorPush("EventEditPage.qml", { defaultDate: d })
    }

    states: State {
        name: "hidePageStackIndicator"
        when: root.status != PageStatus.Inactive
        PropertyChanges { target: app.indicatorParentItem; opacity: 0. }
    }
    transitions: Transition {
        NumberAnimation { properties: "opacity" }
    }

    WallClock {
        id: wallClock
        updateFrequency: WallClock.Day
    }

    SilicaListView {
        id: view
        anchors.fill: parent

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
                //% "Go to today"
                text: qsTrId("calendar-me-go_to_today")
                onClicked: datePicker.date = new Date()
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
        }

        header: Item {
            width: view.width
            height: dateHeader.height + (isPortrait ? datePicker.height : Theme.paddingLarge)
        }

        model: AgendaModel { id: agendaModel }

        delegate: DeletableListDelegate {
            // Update activeDay after the contents of agendaModel changes (after the initial update)
            // to prevent delegates from recalculating time labels before agendaModel responds to
            // changes in datePicker.date

            x: isPortrait ? 0 : datePicker.width + Theme.paddingSmall
            width: isPortrait ? view.width : view.width - datePicker.width

            Component.onCompleted: activeDay = agendaModel.startDate

            Connections {
                target: agendaModel
                onUpdated: activeDay = agendaModel.startDate
            }
        }

        Binding {
            target: agendaModel
            property: "startDate"
            value: datePicker.date
            when: !datePicker.viewMoving
        }

        Connections {
            target: !root.initialLoadDone ? agendaModel : null
            onUpdated: root.initialLoadDone = true
        }

        VerticalScrollDecorator {}
        DatePickerPanel {
            id: datePicker
            parent: view.contentItem
            y: view.headerItem.y
            width: isPortrait ? parent.width
                              : (Screen.sizeCategory > Screen.Medium ? parent.width*0.5 : parent.width*0.55)
        }

        Column {
            width: isPortrait ? view.width : view.width - datePicker.width
            parent: view.contentItem
            x: isPortrait ? 0 : datePicker.width
            y: isPortrait ? datePicker.y + datePicker.height : view.headerItem.y + Theme.paddingLarge

            BackgroundItem {
                id: dateHeader
                width: parent.width
                height: Screen.sizeCategory > Screen.Medium ? Theme.itemSizeMedium : Theme.itemSizeExtraSmall
                onClicked: {
                    var date = datePicker.date
                    var hours = 8
                    var now = new Date()

                    if (date.getFullYear() === now.getFullYear() && date.getMonth() === now.getMonth()
                            && date.getDate() === now.getDate()) {
                        hours = now.getHours()
                    } else if (agendaModel.count > 0) {
                        for (var i = 0; i < agendaModel.count; i++) {
                            if (!agendaModel.get(i, AgendaModel.EventObjectRole).allDay) {
                                hours = agendaModel.get(0, AgendaModel.OccurrenceObjectRole).startTime.getHours()
                                break
                            }
                        }
                    }

                    // Add one hour top padding to day view position
                    date.setHours(Math.max(0, hours - 1))

                    var obj = pageStack.animatorPush("DayPage.qml", { "width": root.width, "date": date })
                    obj.pageCompleted.connect(function(page) {
                        page.statusChanged.connect(function() {
                            if (page.status === PageStatus.Deactivating)
                                datePicker.date = page.date
                        })
                    })
                }

                Label {
                    id: dateLabel
                    anchors {
                        right: moreImage.left
                        rightMargin: Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    text: Util.formatDateWeekday(datePicker.date)
                    color: dateHeader.highlighted ? Theme.highlightColor : Theme.primaryColor
                    font.pixelSize: Theme.fontSizeLarge
                }

                Image {
                    id: moreImage
                    anchors {
                        right: parent.right
                        rightMargin: Screen.sizeCategory > Screen.Medium ? Theme.horizontalPageMargin : Theme.paddingMedium
                        verticalCenter: parent.verticalCenter
                    }
                    source: "image://theme/icon-m-right?" + (dateHeader.highlighted ? Theme.highlightColor
                                                                                    : Theme.primaryColor)
                }
            }

            Item {
                width: parent.width
                height: placeholderText.height + 2*Theme.paddingLarge
                visible: view.count === 0 && root.initialLoadDone

                Label {
                    id: placeholderText
                    x: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 2*Theme.horizontalPageMargin
                    //% "Your schedule is free"
                    text: qsTrId("calendar-me-schedule_is_free")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeHuge
                    color: Theme.secondaryHighlightColor
                }
            }
        }
    }
}

