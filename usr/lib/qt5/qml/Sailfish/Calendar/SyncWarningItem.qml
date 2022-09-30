import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0

Item {
    id: root
    property bool highlighted: true
    property int syncFailure: CalendarEvent.NoSyncFailure
    property bool withDetails
    property alias color: syncFailureLabel.color

    height: Math.max(syncFailureLabel.height, syncFailureLabel.height) + 2 * Theme.paddingSmall

    HighlightImage {
        id: syncFailureIcon
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
        }
        highlighted: root.highlighted
        source: "image://theme/icon-s-warning"
    }
    Label {
        id: syncFailureLabel
        anchors {
            verticalCenter: parent.verticalCenter
            left: syncFailureIcon.right
            leftMargin: Theme.paddingMedium
        }
        width: parent.width - syncFailureIcon.width - Theme.paddingMedium
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
        text: {
            //% "Problem with syncing."
            var head = qsTrId("sailfish_calendar-la-sync_failure")
            if (!root.withDetails) {
                return head
            } else {
                head = head + "\n"
            }
            switch (root.syncFailure) {
            case CalendarEvent.UploadFailure:
                //% "The last modifications done on device failed to be copied to the web."
                return head + qsTrId("sailfish_calendar-la-sync_failure_upload")
            case CalendarEvent.UpdateFailure:
                //% "This event on device does not reflect the lastest modifications done on the web."
                return head + qsTrId("sailfish_calendar-la-sync_failure_update")
            case CalendarEvent.DeleteFailure:
                //% "This event has been deleted on the web, but cannot be removed from the device."
                return head + qsTrId("sailfish_calendar-la-sync_failure_delete")
            case CalendarEvent.NoSyncFailure:
                return "" // Won't be visible in that case
            }
        }
    }
}
