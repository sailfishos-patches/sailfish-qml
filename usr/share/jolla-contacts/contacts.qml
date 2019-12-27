import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import Nemo.DBus 2.0
import org.nemomobile.contacts 1.0

import "pages"
import "pages/common/PageCache.js" as PageCache

ApplicationWindow {
    id: app

    cover: Qt.resolvedUrl("cover/ContactsActiveCover.qml")
    initialPage: Component {
        ContactsListPage {
            id: page
            Component.onCompleted: app.contactList = page
        }
    }
    allowedOrientations: Screen.sizeCategory > Screen.Medium
                         ? defaultAllowedOrientations
                         : defaultAllowedOrientations & Orientation.PortraitMask
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    property Page contactList

    DBusAdaptor {
        service: "com.jolla.contacts.ui"
        path: "/com/jolla/contacts/ui"
        iface: "com.jolla.contacts.ui"

        property string lastCreatedNumber
        property int lastShownContact

        signal createContact(variant attributes)
        signal showContact(int contactId)
        signal editContact(int contactId)
        signal importWizard()
        signal importContactFile(variant pathList)
        signal importContactsFromSim(string simModemPath)
        signal removeAllDeviceContacts()

        onCreateContact: {
            returnToList()
            contactList.openNewContactEditor(attributes, PageStackAction.Immediate)
            activate()
        }

        onShowContact: {
            returnToList()
            contactList.openContactCard(contactList.allContactsModel.personById(contactId),
                                        PageStackAction.Immediate)
            activate()
        }

        onEditContact: {
            returnToList()
            contactList.openContactEditor(contactList.allContactsModel.personById(contactId),
                                          PageStackAction.Immediate)
            activate()
        }

        onImportWizard: {
            returnToList()
            contactList.openImportWizard()
            activate()
        }

        onImportContactFile: {
            // For compatibility reasons this signal sometimes receives an array of strings
            var filePath
            if (typeof pathList === 'string') {
                filePath = pathList
            } else if (typeof pathList === 'object' && pathList.length !== undefined && pathList.length > 0) {
                filePath = pathList[0]
                if (pathList.length > 1) {
                    console.warn('Importing only first path from:', pathList)
                }
            }
            if (filePath && (String(filePath) != '')) {
                returnToList()
                contactList.openImportPage({"importSourceUrl": filePath})
                activate()
            }
        }

        onImportContactsFromSim: {
            if (simModemPath != "") {
                returnToList()
                contactList.openImportPage({"importSourceModemPath": simModemPath})
                activate()
            }
        }

        onRemoveAllDeviceContacts: {
            returnToList()
            contactList.openRemoveAllPage()
            activate()
        }
    }

    function returnToList() {
        if (pageStack.currentPage != contactList) {
            pageStack.pop(contactList, PageStackAction.Immediate)
        }
    }

    function openSearch() {
        returnToList()
        contactList.openSearch()
        activate()
    }

    FirstTimeUseCounter {
        id: counter
        limit: 1
        defaultValue: 1
        key: "/sailfish/people/use_count"
    }
    Timer {
        id: firstUseTimer

        // On first use, push the first-use page 500ms after the app comes up.
        // This interval is calculated so that the user gets to see that they did
        // in fact open the People app, but the transition occurs before they get
        // a chance to do anything else prior to the first-use page transition.
        interval: 500
        onTriggered: contactList.openImportWizard()
    }

    property bool _activated: false
    onApplicationActiveChanged: {
        if (!_activated && applicationActive) {
            _activated = true

            // Have we run the People app before?
            if (counter.active) {
                counter.increase()
                firstUseTimer.start()
            }
        }
    }
}
