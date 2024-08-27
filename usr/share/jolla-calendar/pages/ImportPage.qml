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
import Nemo.Notifications 1.0 as SystemNotifications

Dialog {
    // Set one of fileName or icsString, but not both
    property alias fileName: importModel.fileName
    property alias icsString: importModel.icsString
    property bool _dropInvitation

    width: parent.width
    height: parent.height
    objectName: "ImportPage"
    canAccept: !importModel.error
    onAccepted: {
        var importSuccess = importModel.save(_dropInvitation)
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
        targetNotebook: query.targetUid
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

        acceptText: importModel.hasDuplicates
            //% "Overwrite"
            ? qsTrId("calendar-ph-event_edit_overwrite")
            //% "Import"
            : qsTrId("calendar-ph-event_edit_import")
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
            height: (importModel.error ? errorLabel.height : (calendarSelector.height + (dropInvitationSwitch.visible ? dropInvitationSwitch.height : 0))) + Theme.paddingLarge
            onHeightChanged: listView.contentY = -height

            CalendarSelector {
                id: calendarSelector

                anchors.top: parent.top
                anchors.topMargin: Theme.paddingLarge
                visible: !importModel.error
                //: Shown as placeholder for non-existant notebook, e.g. when default notebook has been deleted
                //% "(none)"
                name: !query.isValid ? qsTrId("calendar-nonexistant_notebook")
                                     : query.name
                localCalendar: query.localCalendar
                description: query.isValid ? query.description : ""
                color: listView.color

                onClicked: pageStack.animatorPush(calendarPicker, {"selectedCalendarUid": query.targetUid})
            }
            TextSwitch {
                id: dropInvitationSwitch

                anchors.bottom: parent.bottom
                visible: importModel.hasInvitations && !importModel.error
                //% "Remove attendees"
                text: qsTrId("calendar-drop_invitation")
                //% "Invitations with attendees are owned by the organizer and cannot be modified on the device"
                description: qsTrId("calendar-detail_external_invitation")
                onCheckedChanged: _dropInvitation = checked
            }
            Label {
                id: errorLabel

                visible: importModel.error
                anchors.bottom: parent.bottom
                text: fileName !== ""
                      //% "Error importing calendar file: %1"
                      ? qsTrId("calendar-error_importing_file").arg(fileName)
                      //% "Error importing calendar data"
                      : qsTrId("calendar-error_importing_data")
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
                    width: root.width - 3*Theme.paddingMedium - colorBar.width

                    ImportEventDate {
                        startDate: root.occurrence ? root.occurrence.startTime : new Date(-1)
                        endDate: root.occurrence ? root.occurrence.endTime : new Date(-1)
                        allDay: root.event && root.event.allDay
                        width: parent.width
                        font.pixelSize: Theme.fontSizeLarge
                        truncationMode: TruncationMode.Fade
                        color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    }

                    Label {
                        width: parent.width
                        text: CalendarTexts.ensureEventTitle(root.event ? root.event.displayLabel : "")
                        font.pixelSize: Theme.fontSizeMedium
                        truncationMode: TruncationMode.Fade
                        color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }

                    Row {
                        height: Math.max(iconWarning.height, textWarning.height) + 2 * Theme.paddingSmall
                        visible: duplicate || invitation
                        spacing: Theme.paddingMedium
                        HighlightImage {
                            id: iconWarning
                            anchors.verticalCenter: parent.verticalCenter
                            highlighted: root.highlighted
                            source: "image://theme/icon-s-warning"
                        }
                        Column {
                            id: textWarning
                            anchors.verticalCenter: parent.verticalCenter
                            width: root.width - iconWarning.width
                            Label {
                                visible: duplicate
                                width: parent.width
                                //% "Event already exists"
                                text: qsTrId("calendar-error_importing-duplicate")
                                wrapMode: Text.Wrap
                            }
                            Label {
                                visible: invitation
                                width: parent.width
                                //% "Event is an invitation"
                                text: qsTrId("calendar-error_importing-invitation")
                                wrapMode: Text.Wrap
                            }
                        }
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
