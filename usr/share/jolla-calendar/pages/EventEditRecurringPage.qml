import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0

Page {
    id: root

    property QtObject event
    property QtObject occurrence
    property var saveStartedCb

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
            text: qsTrId("calendar-event-he-edit_recurring")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*Theme.horizontalPageMargin
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeMedium
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            //% "Do you want to edit this event or the series"
            text: qsTrId("calendar-event-edit_recurring_confirmation")
        }
    }


    ButtonLayout {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: _smallLandscape ? Theme.itemSizeExtraSmall : Theme.itemSizeMedium
        preferredWidth: Theme.buttonWidthMedium

        Button {
            //% "Edit this event"
            text: qsTrId("calendar-event-edit_occurrence")
            onClicked: {
                pageStack.animatorReplace("EventEditPage.qml", { event: root.event,
                                              occurrence: root.occurrence,
                                              saveStartedCb: root.saveStartedCb })
            }
        }

        Button {
            ButtonLayout.newLine: true
            //% "Edit the series"
            text: qsTrId("calendar-event-edit_all_occurrences")
            onClicked: {
                pageStack.animatorReplace("EventEditPage.qml", { event: root.event })
            }
        }
    }
}
