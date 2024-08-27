import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Calendar.syncHelper 1.0

Page {
    id: root

    property QtObject event
    property string instanceId
    property string calendarUid
    property date startTime

    property bool _smallLandscape: isLandscape && Screen.sizeCategory <= Screen.Medium

    Column {
        y: _smallLandscape ? Theme.paddingLarge : Theme.itemSizeExtraLarge
        width: parent.width
        spacing: _smallLandscape ? Theme.itemSizeExtraSmall : Theme.itemSizeSmall

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*Theme.horizontalPageMargin
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeExtraLarge
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            //% "This is a recurring event"
            text: qsTrId("calendar-event-ph-delete_recurring")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*Theme.horizontalPageMargin
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeMedium
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            //% "Confirm, if you want to delete this event, later events or all events."
            text: qsTrId("calendar-event-delete_confirmation")
        }
    }


    ButtonLayout {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: _smallLandscape ? Theme.itemSizeExtraSmall : Theme.itemSizeMedium
        preferredWidth: Theme.buttonWidthMedium

        Button {
            //% "Delete this event"
            text: qsTrId("calendar-event-delete_occurrence")
            onClicked: {
                Calendar.remove(instanceId, startTime)
                app.syncHelper.triggerUpdateDelayed(calendarUid)
                app.showMainPage()
            }
        }

        Button {
            ButtonLayout.newLine: true
            //% "Delete this and future events"
            text: qsTrId("calendar-event-delete_all_future_occurences")
            onClicked: {
                var modification = Calendar.createModification(root.event)
                // setRecurEndDate() is inclusive.
                modification.setRecurEndDate(QtDate.addDays(startTime, -1))
                modification.save()
                app.syncHelper.triggerUpdateDelayed(calendarUid)
                app.showMainPage()
            }
        }

        Button {
            ButtonLayout.newLine: true
            //% "Delete the series"
            text: qsTrId("calendar-event-delete_all_occurences")
            onClicked: {
                Calendar.removeAll(instanceId)
                app.syncHelper.triggerUpdateDelayed(calendarUid)
                app.showMainPage()
            }
        }
    }
}

