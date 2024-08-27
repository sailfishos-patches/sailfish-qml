import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0

Item {
    id: root
    property bool highlighted: true
    property int syncFailure: CalendarEvent.NoSyncFailure
    property alias color: syncFailureLabel.color

    height: Math.max(syncFailureLabel.height, syncFailureIcon.height)

    HighlightImage {
        id: syncFailureIcon
        anchors.verticalCenter: parent.verticalCenter
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
        //% "Problem with syncing."
        text: qsTrId("sailfish_calendar-la-sync_failure")
    }
}
