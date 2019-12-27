import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0

Page {
    id: root

    property int _removedCount
    property bool _error

    onStatusChanged: {
        if (status === PageStatus.Active) {
            busyIndicator.running = true
            remover.removeDeviceContacts()
        } else if (status === PageStatus.Deactivating) {
            remover.cancel()
        }
    }

    function _statusText() {
        if (busyIndicator.running) {
            //: Removing device contacts in progress
            //% "Removing contacts from device..."
            return qsTrId("contacts-la-removing_contacts")
        } else if (_error) {
            //: Error while removing contacts from device
            //% "Unable to remove contacts from device."
            return qsTrId("contacts-la-failed_to_remove_contacts")
        } else if (_removedCount > 0) {
            //% "Removed %n contact(s)."
            return qsTrId("contacts-la-removed_n_contacts", _removedCount)
        } else {
            //% "No contacts removed."
            return qsTrId("contacts-la-no_contacts_removed")
        }
    }

    Column {
        x: Theme.horizontalPageMargin
        width: parent.width - x*2

        PageHeader {
            // no text set, used for spacing only
        }

        Label {
            width: parent.width
            height: implicitHeight + Theme.paddingLarge
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeExtraLarge
            wrapMode: Text.Wrap

            //% "Remove device contacts"
            text: qsTrId("contacts-he-remove_device_contacts")
        }

        Label {
            width: parent.width
            height: implicitHeight + Theme.paddingLarge
            color: Theme.secondaryHighlightColor
            wrapMode: Text.Wrap
            text: root._statusText()
        }

        BusyIndicator {
            id: busyIndicator
            anchors.horizontalCenter: parent.horizontalCenter
            size: BusyIndicatorSize.Large
        }
    }

    ContactsRemover {
        id: remover
        onRemovingFinished: {
            busyIndicator.running = false
            root._removedCount = removedCount
        }
        onRemovingFailed: {
            busyIndicator.running = false
            root._error = true
        }
    }
}
