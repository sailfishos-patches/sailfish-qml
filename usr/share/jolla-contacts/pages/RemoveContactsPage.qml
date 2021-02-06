import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0

Page {
    id: root

    property bool removeAllContacts
    property var contactsToRemove: []

    property int _removedCount
    property bool _error

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (removeAllContacts || contactsToRemove.length > 0) {
                busyIndicator.running = true
                if (removeAllContacts) {
                    remover.removeAllDeviceContacts()
                } else {
                    remover.removeContacts(contactsToRemove)
                }
            }
        } else if (status === PageStatus.Deactivating) {
            remover.cancel()
        }
    }

    function _statusText() {
        if (!removeAllContacts && contactsToRemove.length === 0) {
            //% "No contacts selected."
            return qsTrId("contacts-la-no_contacts_selected")
        } else if (busyIndicator.running) {
            if (contactsToRemove.length > 0) {
                //: Removing contacts in progress. %n = number of contacts being removed
                //% "Removing %n contact(s)"
                return qsTrId("contacts-la-removing_contacts_count", contactsToRemove.length)
            } else {
                //: Removing contacts in progress
                //% "Removing contacts"
                return qsTrId("contacts-la-removing_contacts_in_progress")
            }
        } else if (_error) {
            //: Error while removing contacts
            //% "Unable to remove contacts."
            return qsTrId("contacts-la-unable_to_remove_contacts")
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

            //% "Remove contacts"
            text: qsTrId("contacts-he-remove_contacts")
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
