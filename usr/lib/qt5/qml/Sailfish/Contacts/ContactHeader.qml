import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

Column {
    id: root

    property var contact
    property bool readOnly

    signal contactModified
    signal editClicked

    function getNameText() {
        if (contact) {
            if (contact.primaryName && contact.secondaryName) {
                return contact.primaryName + '\n' + contact.secondaryName
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
                items.push(contact.companyName)
            }
            if (contact.department) {
                items.push(contact.department)
            }
            if (contact.title || contact.role) {
                if (contact.title) {
                    items.push(contact.title)
                } else {
                    items.push(contact.role)
                }
            }
            return items.join(', ')
        }
        return ''
    }
    width: parent ? parent.width : 0

    topPadding: Theme.paddingMedium
    spacing: Theme.paddingMedium

    IconButton {
        // favorite button
        width: Theme.itemSizeSmall
        height: width
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin - Theme.paddingLarge
        }
        icon.source: !contact || contact.id === 0
                   ? "" // don't show any icon in the TemporaryContactCardPage case.
                   : contact && contact.favorite ? "image://theme/icon-m-favorite-selected"
                                                 : "image://theme/icon-m-favorite"
        // Note - enabled even in readOnly case:
        enabled: !!contact && contact.id !== 0 && contact.complete
        onClicked: {
            contact.favorite = !contact.favorite
            contactModified()
        }
    }

    ListItem {
        id: highlightArea

        onClicked: openMenu()

        highlightedColor: "transparent"

        contentHeight: {
            // avoid just a few pixel padding below the avatar
            var avatarHeight = avatar.height + 2 * avatar.y
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

                MenuItem {
                    //: Edit a particular detail value, e.g. phone number or email address
                    //% "Edit"
                    text: qsTrId("components_contacts-me-edit_detail")
                    onClicked: root.editClicked()
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.rgba(Theme.highlightBackgroundColor, highlightArea.menuOpen ? 0.1 : Theme.highlightBackgroundOpacity)
        }

        AvatarImage {
            id: avatar

            readonly property bool emailOnly: !!contact
                       && contact.emailDetails.length > 0
                       && contact.phoneDetails.length === 0
                       && contact.addressDetails.length === 0
                       && contact.accountDetails.length === 0
                       && contact.websiteDetails.length === 0

            y: available ? 0 : Theme.paddingMedium
            x: available ? 0 : Theme.horizontalPageMargin

            // binding to visible makes the header refetch the avatar when returning to the view
            source: contact && visible ? contact.filteredAvatarUrl(['local', 'picture', '']) : ""

            width: available ? itemSize : avatarPlaceholder.width
            height: available ? itemSize : avatarPlaceholder.height + 2 * y

            HighlightImage {
                id: avatarPlaceholder

                anchors.centerIn: parent
                visible: !avatar.available
                highlighted: highlightArea.highlighted
                source: avatar.emailOnly ? "image://theme/icon-m-mail"
                                         : "image://theme/icon-m-contact"
            }
        }

        Column {
            id: labelColumn

            topPadding: Theme.paddingMedium
            spacing: Theme.paddingSmall
            anchors {
                left: avatar.right
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
        }
    }
}

