/*
 * Copyright (c) 2012 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0 as SailfishContacts
import org.nemomobile.contacts 1.0

Column {
    id: root

    property var contact
    property var simManager

    function getNameText() {
        if (contact) {
            var firstNameFirst = SailfishContacts.ContactModelCache.unfilteredModel().displayLabelOrder === PeopleModel.FirstNameFirst

            var names = []

            if (contact.primaryName) {
                names.push(contact.primaryName)
            }

            if (firstNameFirst && contact.middleName) {
                names.push(contact.middleName)
            }

            if (contact.secondaryName) {
                names.push(contact.secondaryName)
            }

            if (!firstNameFirst && contact.middleName) {
                names.push(contact.middleName)
            }

            if (names.length > 0) {
                return names.join('\n')
            }

            return contact.primaryName || contact.secondaryName || contact.displayLabel
        }
        return ''
    }

    function getDetailText() {
        if (contact && contact.complete) {
            var items = []
            // TODO: find the 'preferred' nickname
            var nicknames = contact.nicknameDetails
            for (var i = 0; i < nicknames.length; ++i) {
                // If the contact nickname is already the display label, don't show it here
                if (nicknames[i].nickname != getNameText()) {
                    items.push(nicknames[i].nickname)
                    // Only use one nickname
                    break
                }
            }
            if (contact.companyName) {
                // Don't show company name if it duplicates the displayed name
                if (contact.companyName != getNameText()) {
                    items.push(contact.companyName)
                }
            }
            if (contact.department) {
                items.push(contact.department)
            }
            if (contact.title) {
                items.push(contact.title)
            }
            if (contact.role) {
                items.push(contact.role)
            }
            return items.join(', ')
        }
        return ''
    }

    width: parent ? parent.width : 0

    topPadding: Theme.paddingMedium
    spacing: Theme.paddingMedium

    onContactChanged: {
        if (contact && contact.id !== 0) {
            contact.fetchConstituents()
        }
    }

    IconButton {
        // favorite button
        width: Theme.itemSizeSmall
        height: width
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin - Theme.paddingLarge
        }
        icon.source: !contact || contact.id === 0
                   ? "" // don't show any icon if the contact is invalid (e.g. viewing an unsaved contact)
                   : ((favoriteModifier.lastStatusValid ? favoriteModifier.lastStatus : contact.favorite)
                      ? "image://theme/icon-m-favorite-selected"
                      : "image://theme/icon-m-favorite")
        enabled: !!contact && contact.id !== 0 && contact.complete
        onPressed: {
            favoriteModifier.setFavoriteStatus(contact, !contact.favorite)
        }
    }

    ContactFavoriteModifier {
        id: favoriteModifier

        peopleModel: SailfishContacts.ContactModelCache.unfilteredModel()
    }

    ListItem {
        id: highlightArea

        onClicked: openMenu()

        highlightedColor: "transparent"

        contentHeight: {
            // avoid just a few pixel padding below the avatar
            var avatarHeight = avatarArea.height + 2 * avatarArea.y
            if (labelColumn.height + Theme.paddingSmall < avatarHeight) {
                return avatarHeight
            } else {
                return labelColumn.height + Theme.paddingMedium
            }
        }

        width: parent.width
        menu: Component {
            ContextMenu {
                MenuItem {
                    //: Menu option to copy the contact's display name shown in the contact card header
                    //% "Copy name"
                    text: qsTrId("components_contacts-me-copy_contact_name")
                    visible: nameLabel.text.length > 0
                    onClicked: Clipboard.text = nameLabel.text.replace("\n", " ")
                }

                MenuItem {
                    //: Menu option to copy the contact's extra details shown in the contact card header
                    //% "Copy details"
                    text: qsTrId("components_contacts-me-copy_contact_information")
                    visible: extraDetailLabel.text.length > 0
                    onClicked: Clipboard.text = extraDetailLabel.text
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.rgba(Theme.highlightBackgroundColor, highlightArea.menuOpen ? 0.1 : Theme.highlightBackgroundOpacity)
        }

        Item {
            id: avatarArea

            readonly property bool emailOnly: !!contact
                       && contact.emailDetails.length > 0
                       && contact.phoneDetails.length === 0
                       && contact.addressDetails.length === 0
                       && contact.accountDetails.length === 0
                       && contact.websiteDetails.length === 0

            y: avatar.available ? 0 : Theme.paddingMedium
            x: avatar.available ? 0 : Theme.horizontalPageMargin

            width: avatar.available ? avatar.itemSize : avatarPlaceholder.width
            height: avatar.available ? avatar.itemSize : avatarPlaceholder.height + 2 * y

            AvatarImage {
                id: avatar
                anchors.centerIn: parent

                // binding to avatarUrl ensures the source is refreshed if avatar changes
                source: !!contact ? contact.avatarUrl : ""
            }

            HighlightImage {
                id: avatarPlaceholder

                anchors.centerIn: parent
                visible: !avatar.available
                highlighted: highlightArea.highlighted
                source: avatarArea.emailOnly ? "image://theme/icon-m-mail"
                                             : "image://theme/icon-m-contact"
            }
        }

        Column {
            id: labelColumn

            // Avoid top alignment when showing 1 line next to the small avatar placeholder.
            topPadding: !avatar.available && nameLabel.lineCount === 1 && extraDetailLabel.text.length === 0
                        ? 0
                        : Theme.paddingSmall
            y: topPadding === 0 ? Math.max(0, avatarArea.y + (avatarArea.height/2 - height/2)) : 0

            spacing: Theme.paddingSmall
            anchors {
                left: avatarArea.right
                leftMargin: Theme.paddingLarge
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
            }

            Label {
                id: nameLabel
                width: parent.width
                font {
                    family: Theme.fontFamilyHeading
                    pixelSize: Theme.fontSizeLarge
                }
                color: highlightArea.highlighted ? Theme.highlightColor : Theme.primaryColor

                wrapMode: Text.Wrap
                maximumLineCount: 10
                text: getNameText()
            }

            Label {
                id: extraDetailLabel
                width: parent.width
                height: text.length > 0 ? implicitHeight : 0
                font {
                    family: Theme.fontFamilyHeading
                    pixelSize: Theme.fontSizeExtraSmall
                }
                color: highlightArea.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                wrapMode: Text.Wrap
                maximumLineCount: 30
                text: getDetailText()
            }

            Flow {
                width: parent.width
                spacing: Theme.paddingSmall
                visible: !!root.contact && root.contact.id > 0

                Repeater {
                    id: addressBookIcons

                    delegate: Image {
                        source: modelData
                        sourceSize.width: Theme.iconSizeSmall
                        sourceSize.height: Theme.iconSizeSmall
                    }
                }

                Label {
                    //% "Address books(s)"
                    text: qsTrId("components_contacts-la-address_books", addressBookModel.count)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }
        }
    }

    AddressBookModel {
        id: addressBookModel

        contactId: !!root.contact ? root.contact.id : -1

        onCountChanged: {
            if (!root.contact || root.contact.id === 0) {
                return
            }
            var uniqueIcons = []
            for (var i = 0; i < count; ++i) {
                var addressBook = addressBookAt(i)
                var accountProvider = SailfishContacts.ContactAccountCache.accountManager.providerForAccount(addressBook.accountId)
                var icon = SailfishContacts.ContactsUtil.addressBookIconUrl(addressBook, accountProvider)
                if (icon.length > 0 && uniqueIcons.indexOf(icon) < 0) {
                    uniqueIcons.push(icon)
                }
            }
            addressBookIcons.model = uniqueIcons
        }
    }
}
