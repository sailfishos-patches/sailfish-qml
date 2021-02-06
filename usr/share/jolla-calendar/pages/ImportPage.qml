/****************************************************************************
**
** Copyright (C) 2015 - 2019 Jolla Ltd.
** Copyright (C) 2020 Open Mobile Platform LLC.
**
****************************************************************************/

import QtQuick 2.0
import org.nemomobile.calendar 1.0
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0
import org.nemomobile.notifications 1.0 as SystemNotifications

Dialog {
    // Set one of fileName or icsString, but not both
    property alias fileName: importModel.fileName
    property alias icsString: importModel.icsString

    width: parent.width
    height: parent.height
    objectName: "ImportPage"
    canAccept: !importModel.error
    onAccepted: {
        var importSuccess = importModel.importToNotebook(query.targetUid)
        systemNotification.body = importSuccess
                ? //% "Import successful"
                  qsTrId("jolla-calendar-import-successfull")
                : //% "Import failed"
                  qsTrId("jolla-calendar-import-failed")
        systemNotification.publish()
    }

    SystemNotifications.Notification {
        id: systemNotification

        appIcon: "icon-lock-calendar"
        isTransient: true
    }

    ImportModel {
        id: importModel
    }

    NotebookQuery {
        id: query

        targetUid: Calendar.defaultNotebook
    }

    Component {
        id: calendarPicker

        CalendarPicker {
            hideExcludedCalendars: true
            onCalendarClicked: {
                query.targetUid = uid
                selectedCalendarUid = uid
                pageStack.pop()
            }
        }
    }

    DialogHeader {
        id: dialogHeader

        //% "Import"
        acceptText: qsTrId("calendar-ph-event_edit_import")
        spacing: 0
    }

    SilicaListView {
        id: listView

        property string color: query.isValid ? query.color : "transparent"

        anchors {
            top: dialogHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        clip: true

        header: Item {
            width: listView.width
            height: (importModel.error ? errorLabel.height : calendarSelector.height) + Theme.paddingLarge
            onHeightChanged: listView.contentY = -height

            CalendarSelector {
                id: calendarSelector

                visible: !importModel.error
                anchors.bottom: parent.bottom
                //: Shown as placeholder for non-existant notebook, e.g. when default notebook has been deleted
                //% "(none)"
                name: !query.isValid ? qsTrId("calendar-nonexistant_notebook")
                                     : query.name
                localCalendar: query.localCalendar
                description: query.isValid ? query.description : ""
                color: listView.color

                onClicked: pageStack.animatorPush(calendarPicker, {"selectedCalendarUid": query.targetUid})
            }
            Label {
                id: errorLabel

                visible: importModel.error
                anchors.bottom: parent.bottom
                text: fileName !== ""
                      //% "Error importing calendar file: %1"
                      ? qsTrId("calendar-error_importing_file").arg(fileName)
                      // Duplicated string from above: "Import failed"
                      : qsTrId("jolla-calendar-import-failed")
                color: Theme.highlightColor
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                wrapMode: Text.Wrap
            }
        }

        model: importModel

        delegate: BackgroundItem {
            id: root

            property QtObject event: importModel.getEvent(index)
            property QtObject occurrence: event ? event.nextOccurrence() : null

            height: Math.max(Theme.itemSizeSmall, content.height + 2*Theme.paddingSmall)
            width: parent.width

            Row {
                id: content
                x: Theme.paddingMedium
                height: column.height
                spacing: Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: colorBar

                    width: Theme.paddingSmall
                    radius: Math.round(width/3)
                    color: listView.color
                    height: parent.height
                }

                Column {
                    id: column
                    anchors.verticalCenter: parent.verticalCenter

                    ImportEventDate {
                        startDate: root.occurrence ? root.occurrence.startTime : new Date(-1)
                        endDate: root.occurrence ? root.occurrence.endTime : new Date(-1)
                        allDay: root.event && root.event.allDay
                        width: root.width - 3*Theme.paddingMedium - colorBar.width
                        font.pixelSize: Theme.fontSizeLarge
                        truncationMode: TruncationMode.Fade
                        color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor


                    }

                    Label {
                        width: root.width - 3*Theme.paddingMedium - colorBar.width
                        text: root.event ? root.event.displayLabel : ""
                        font.pixelSize: Theme.fontSizeMedium
                        truncationMode: TruncationMode.Fade
                        color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }
                }
            }

            onClicked: {
                event.color = listView.color
                pageStack.animatorPush("ImportEventViewPage.qml",
                                       { "event": event, "occurrence": occurrence })
            }
        }

        VerticalScrollDecorator {}
    }
}
