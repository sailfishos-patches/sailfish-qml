import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Calendar.syncHelper 1.0

Page {
    id: root

    property string uniqueId
    property string recurrenceId
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
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            //% "This is a recurring event"
            text: qsTrId("calendar-event-ph-delete_recurring")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*Theme.horizontalPageMargin
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeMedium
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            //% "Confirm, if you want to delete this event or all events."
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
                Calendar.remove(uniqueId, recurrenceId, startTime)
                app.syncHelper.triggerUpdateDelayed(calendarUid)
                app.showMainPage()
            }
        }

        Button {
            ButtonLayout.newLine: true
            //% "Delete the series"
            text: qsTrId("calendar-event-delete_all_occurences")
            onClicked: {
                Calendar.removeAll(uniqueId)
                app.syncHelper.triggerUpdateDelayed(calendarUid)
                app.showMainPage()
            }
        }
    }
}

