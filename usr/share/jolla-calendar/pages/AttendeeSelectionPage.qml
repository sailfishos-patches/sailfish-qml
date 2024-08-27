import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0 as Contacts // avoid namespace clashes
import Sailfish.Contacts 1.0 as SailfishContacts
import org.nemomobile.calendar 1.0

Page {
    id: root

    property QtObject requiredAttendees
    property QtObject optionalAttendees

    signal modified()

    onStatusChanged: {
        if (status === PageStatus.Active && requiredAttendees.count == 0 && optionalAttendees.count == 0) {
            searchField.forceActiveFocus()
        }
    }

    function removeAttendee(required, index) {
        if (required) {
            requiredAttendees.remove(index)
        } else {
            optionalAttendees.remove(index)
        }

        modified()
    }

    function changeAttendeeParticipation(fromRequired, index) {
        var name
        var email

        if (fromRequired) {
            name = requiredAttendees.name(index)
            email = requiredAttendees.email(index)
            requiredAttendees.remove(index)
            optionalAttendees.prepend(name, email)
        } else {
            name = optionalAttendees.name(index)
            email = optionalAttendees.email(index)
            optionalAttendees.remove(index)
            requiredAttendees.prepend(name, email)
        }

        modified()
    }

    function addRequiredAttendee(name, email) {
        if (requiredAttendees.hasEmail(email) || optionalAttendees.hasEmail(email)) {
            console.log("skipping duplicate email", email)
            return
        }
        requiredAttendees.prepend(name, email)
        modified()
    }

    Contacts.PeopleModel {
        id: contactSearchModel

        filterPattern: searchField.text
        filterType: filterPattern == "" ? Contacts.PeopleModel.FilterNone : Contacts.PeopleModel.FilterAll
        requiredProperty: Contacts.PeopleModel.EmailAddressRequired
    }

    ContactListItem {
        id: dummyContact
        property string displayLabel: "X"
        property var emailDetails: []
        visible: false
    }

    AttendeeListItem {
        id: dummyAttendee
        name: "X"
        email: "X"
        visible: false
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            bottomPadding: Theme.paddingLarge

            PageHeader {
                //% "Invite People"
                title: qsTrId("calendar-ph-invite_people")
            }

            Item {
                height: searchField.height
                width: parent.width

                TextField {
                    id: searchField

                    width: addButton.x
                    textRightMargin: Theme.paddingLarge
                    inputMethodHints: Qt.ImhNoAutoUppercase
                    EnterKey.enabled: text.length > 0
                    EnterKey.onClicked: {
                        // just a rough check here
                        if (text.indexOf("@") > 0 && text.indexOf(".") > 0) {
                            addRequiredAttendee("", text)
                            text = ""
                        } else {
                            invalidEmailTimer.restart()
                        }
                    }

                    //% "Search"
                    placeholderText: qsTrId("calendar-search_contact")
                    label: invalidEmailTimer.running
                           ? //% "Invalid email address"
                             qsTrId("calendar-invalid_email_address")
                           : placeholderText

                    Timer {
                        id: invalidEmailTimer
                        interval: 2000
                    }
                }

                IconButton {
                    id: addButton
                    anchors.verticalCenter: searchField.Center
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.horizontalPageMargin
                    icon.source: "image://theme/icon-m-add"
                    onClicked: {
                        var pickerPage = pageStack.push("Sailfish.Contacts.ContactsMultiSelectDialog",
                                                        {"requiredProperty": Contacts.PeopleModel.EmailAddressRequired})
                        pickerPage.accepted.connect(function() { addContacts(pickerPage.selectedContacts) })
                    }

                    function addContacts(contacts) {
                        for (var i = 0; i < contacts.count; i++) {
                            var contact = contactSearchModel.personById(contacts.get(i), SailfishContacts.ContactSelectionModel.ContactIdRole)
                            var property = contacts.get(i, SailfishContacts.ContactSelectionModel.PropertyRole)
                            addRequiredAttendee(contact.displayLabel, property.address)
                        }
                    }
                }
            }

            ColumnView {
                id: filteredContacts

                itemHeight: dummyContact.height
                model: contactSearchModel
                delegate: ContactListItem {
                    searchText: searchField.text
                    openMenuOnPressAndHold: false
                    onClicked: handleMenu(true)
                    onPressAndHold: handleMenu(false)
                    menu: Component {
                        ContextMenu {
                            Repeater {
                                model: emailsModel
                                MenuItem {
                                    text: email
                                    onClicked: {
                                        addRequiredAttendee(name, email)
                                        searchField.text = ""
                                        searchField.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                    function handleMenu(click) {
                        var emails = Contacts.Person.removeDuplicateEmailAddresses(emailDetails)

                        if (emails.length > 1) {
                            emailsModel.clear()
                            for (var i=0; i < emails.length; ++i) {
                                emailsModel.append({"name": displayLabel, "email": emails[i].address})
                            }
                            openMenu()
                        } else if (click && emails.length == 1) {
                            addRequiredAttendee(displayLabel, emails[0].address)
                            searchField.text = ""
                            searchField.forceActiveFocus()
                        }
                    }
                }

                ListModel {
                    id: emailsModel
                }
            }

            SectionHeader {
                visible: requiredAttendees.count > 0
                //% "Invited"
                text: qsTrId("calendar-invited_attendee")
            }

            ColumnView {
                model: requiredAttendees
                itemHeight: dummyAttendee.height
                delegate: AttendeeListItem {
                    required: true
                    name: model.name
                    email: model.email
                    onRemoved: root.removeAttendee(true, index)
                    onMoved: changeAttendeeParticipation(true, index)
                }
            }

            SectionHeader {
                visible: optionalAttendees.count > 0
                //% "Optional"
                text: qsTrId("calendar-optional_attendee")
            }

            ColumnView {
                model: optionalAttendees
                itemHeight: dummyAttendee.height
                delegate: AttendeeListItem {
                    name: model.name
                    email: model.email
                    onRemoved: root.removeAttendee(false, index)
                    onMoved: changeAttendeeParticipation(false, index)
                }
            }
        }
    }
}
