import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0
import "common/PageCache.js" as PageCache

Page {
    id: root

    property Person selectedContact
    property PeopleModel favoritesModel: contactBrowser.favoriteContactsModel
    property PeopleModel allContactsModel: contactBrowser.allContactsModel

    ContactBrowser {
        id: contactBrowser

        searchActive: true
        searchableContactProperty: PeopleModel.AccountUriSearchable | PeopleModel.EmailAddressSearchable | PeopleModel.PhoneNumberSearchable | PeopleModel.OrganizationSearchable

        pageHeader: PageHeader {
            // Also translated in strings.qml:
            //: Application name in desktop file
            //% "People"
            title: qsTrId("contacts-ap-name")
            page: root
        }

        //: Displayed when there are no contacts
        //% "Add people"
        placeholderText: qsTrId("contacts-la-add_people")

        onContactClicked: {
            openContactCard(contact, PageStackAction.Animated)
        }

        onContactPressAndHold: {
            contactBrowser.openContextMenu(contact.id, contactContextMenuComponent, {"person": contact})
        }

        Component {
            id: contactContextMenuComponent

            ContactBrowserMenu {
                peopleModel: root.allContactsModel

                onEditContact: {
                    ContactsUtil.editContact(person, root.allContactsModel, pageStack)
                }
            }
        }

        PullDownMenu {
            MenuItem {
                //: Allows the user to select multiple contacts (for deletion or sharing)
                //% "Select contacts"
                text: qsTrId("contacts-me-select_contacts")
                visible: allContactsModel.count > 0
                onClicked: openContactMultiSelectPage()
            }

            MenuItem {
                //: Show contact search view
                //% "Search"
                text: qsTrId("contacts-me-search")
                enabled: allContactsModel.count > 0

                onClicked: contactBrowser.forceSearchFocus()
            }

            MenuItem {
                //: Initiates adding a new contact
                //% "Add contact"
                text: qsTrId("contacts-me-add_contact")
                onClicked: openNewContactEditor()
            }
        }
    }

    /* for the active cover, cache the models in the page cache */
    Component.onCompleted: {
        ContactsUtil.init()
        PageCache.favoritesModel = root.favoritesModel
        PageCache.allContactsModel = root.allContactsModel
    }

    function openContactCard(contact, operationType) {
        if (contact == null || contact == undefined) {
            return null
        }
        pageStack.animatorPush("Sailfish.Contacts.ContactCardPage",
                               {"contact": contact},
                               operationType)
    }

    function openContactEditor(contact, operationType) {
        if (contact == null || contact == undefined) {
            return null
        }
        ContactsUtil.editContact(contact,
                                 root.allContactsModel,
                                 pageStack,
                                 operationType)
    }


    function openContactMultiSelectPage() {
        var obj = pageStack.animatorPush("Sailfish.Contacts.ContactMultiSelectPage")
        obj.pageCompleted.connect(function(page) {
            page.shareClicked.connect(multiSelectShareClicked)
            page.deleteClicked.connect(multiSelectDeleteClicked)
        })
    }


    function multiSelectDeleteClicked(contactsToDelete) {
        // pop the multiSelect page
        pageStack.pop(root)
        // cache contacts in this function to avoid context destruction issues
        var contactModel = root.allContactsModel
        //% "Deleting %n contacts"
        Remorse.popupAction(root, qsTrId("components_contacts-la-removing_multiple_contacts", contactsToDelete.length), function() {
            contactModel.removePeople(contactsToDelete)
        })
    }

    function multiSelectShareClicked(content) {
        pageStack.animatorReplaceAbove(root, "Sailfish.Contacts.ContactSharePage",
                       { "content": content, "shareEndDestination": root })
    }

    function openNewContactEditor(attributes, operationType) {
        ContactsUtil.editContact(ContactCreator.createContact(attributes),
                                 root.allContactsModel,
                                 pageStack,
                                 operationType)
    }

    function openImportWizard(properties) {
        pageStack.animatorPush("ContactImportWizardPage.qml", properties)
    }

    function openImportPage(properties) {
        var obj = pageStack.animatorPush("Sailfish.Contacts.ContactImportPage", properties)
        obj.pageCompleted.connect(function(page) {
            page.contactOpenRequested.connect(function(contactId) {
                if (contactId != undefined) {
                    pageStack.animatorReplace("Sailfish.Contacts.ContactCardPage",
                                              {"contact": root.allContactsModel.personById(contactId)})
                } else {
                    pageStack.pop()
                }
            })
        })
    }

    function openRemoveAllPage() {
        pageStack.animatorPush("RemoveAllPage.qml")
    }

    function openSearch() {
        contactBrowser.forceSearchFocus()
    }
}
