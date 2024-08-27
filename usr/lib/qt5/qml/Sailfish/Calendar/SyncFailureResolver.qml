import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0

Column {
    id: root
    property QtObject event
    property int _syncFailure: event ? event.syncFailure : CalendarEvent.NoSyncFailure

    onEventChanged: combo.select(event ? event.syncFailureResolution : combo.value)

    width: parent.width
    Label {
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * x
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
        color: Theme.secondaryHighlightColor
        text: {
            switch (_syncFailure) {
            case CalendarEvent.CreationFailure:
                //% "The event created on the device failed to be copied to the server."
                return qsTrId("sailfish_calendar-la-sync_failure_create")
            case CalendarEvent.UploadFailure:
                //% "The last modifications done on the device failed to be copied to the server."
                return qsTrId("sailfish_calendar-la-sync_failure_upload")
            case CalendarEvent.UpdateFailure:
                //% "This event on the device does not reflect the latest modifications done on the server."
                return qsTrId("sailfish_calendar-la-sync_failure_update")
            case CalendarEvent.DeleteFailure:
                //% "This event has been deleted on the server, but cannot be removed from the device."
                return qsTrId("sailfish_calendar-la-sync_failure_delete")
            case CalendarEvent.NoSyncFailure:
                return "" // Won't be visible in that case
            }
        }
    }
    ComboBox {
        id: combo
        property int value: currentItem ? currentItem.value : CalendarEvent.RetrySync

        function select(resolution) {
            switch (resolution) {
            case CalendarEvent.KeepOutOfSync:
                currentIndex = 1
                break
            case CalendarEvent.PullServerData:
                currentIndex = 2
                break
            case CalendarEvent.PushDeviceData:
                currentIndex = 3
                break
            default:
                currentIndex = 0
                break
            }
        }
        Connections {
            target: root.event
            onSyncFailureResolutionChanged: combo.select(syncFailureResolution)
        }
        onValueChanged: {
            if (!root.event || value == root.event.syncFailureResolution)
                return
            var modification = Calendar.createModification(root.event)
            modification.syncFailureResolution = value
            modification.save()
        }

        //% "Action"
        label: qsTrId("sailfish_calendar-cb-sync_failure_resolution")
        menu: ContextMenu {
            MenuItem {
                property int value: CalendarEvent.RetrySync
                //% "Retry on next sync"
                text: qsTrId("sailfish_calendar-me-sync_resolution_retry")
            }
            MenuItem {
                property int value: CalendarEvent.KeepOutOfSync
                //% "Keep out of sync"
                text: qsTrId("sailfish_calendar-me-sync_resolution_keep")
            }
            MenuItem {
                property int value: CalendarEvent.PullServerData
                visible: root._syncFailure == CalendarEvent.UploadFailure
                //% "Overwrite local modifications"
                text: qsTrId("sailfish_calendar-me-sync_resolution_reset_with_server")
            }
            MenuItem {
                property int value: CalendarEvent.PushDeviceData
                visible: root._syncFailure == CalendarEvent.UpdateFailure
                    || root._syncFailure == CalendarEvent.DeleteFailure
                text: root._syncFailure == CalendarEvent.UpdateFailure
                    //% "Overwrite remote modifications"
                    ? qsTrId("sailfish_calendar-me-sync_resolution_reset_with_device")
                    //% "Revert remote deletion"
                    : qsTrId("sailfish_calendar-me-sync_resolution_reset_remote_deletion")
            }
        }
    }
}
