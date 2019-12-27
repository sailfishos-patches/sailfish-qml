import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

PullDownMenu {
    id: root

    property var page
    property var peopleModel
    property var contact

    readonly property bool _contactValid: !!contact && contact.id
    property var _peopleModel: peopleModel || ContactModelCache.unfilteredModel()

    signal temporaryContactLinked(var detail)

    function _vCardName(person) {
        // Return a name for this vcard that can be used as a filename

        // Remove any whitespace
        var noWhitespace = person.displayLabel.replace(/\s/g, '')

        // Convert to 7-bit ASCII
        var sevenBit = Format.formatText(noWhitespace, Formatter.Ascii7Bit)
        if (sevenBit.length < noWhitespace.length) {
            // This contact's name is not representable in ASCII
            //: Placeholder name for contact vcard filename
            //% "contact"
            sevenBit = qsTrId("components_contacts-ph-vcard_name")
        }

        // Remove any characters that are not part of the portable filename character set
        return Format.formatText(sevenBit, Formatter.PortableFilename) + '.vcf'
    }

    function _deleteContact() {
        var _contact = contact
        var cache = ContactModelCache
        cache._deletingContactId = contact.id
        var _page = pageStack.previousPage(page)
        pageStack.pop()
        var remorse = Remorse.popupAction(
                    _page,
                    //: Deleted contact, providing a way to undo for 4 seconds
                    //% "Deleted contact"
                    qsTrId("components_contacts-la-deleted_contact"),
                    function() {
                        cache.unfilteredModel().removePerson(_contact)
                        cache._deletingContactId = -1
                    })
        remorse.canceled.connect(function () { cache._deletingContactId = -1 })
    }

    MenuItem {
        //: Deletes contact
        //% "Delete"
        text: qsTrId("components_contacts-me-delete")
        visible: root._contactValid

        onClicked: root._deleteContact()
    }

    MenuItem {
        //: Manage links (associated contacts) for this contact
        //% "Link"
        text: qsTrId("components_contacts-me-link")
        onClicked: {
            if (root._contactValid) {
                pageStack.animatorPush(Qt.resolvedUrl("ContactLinksPage.qml"),
                                       { "person": root.contact } )
            } else {
                var obj = pageStack.animatorPush(Qt.resolvedUrl("TemporaryContactLinkPage.qml"),
                                                 { "temporaryContact": root.contact } )
                obj.pageCompleted.connect(function(page) {
                    page.detailAppended.connect(temporaryContactLinked)
                })
            }
        }
    }

    MenuItem {
        //: Share contact via Bluetooth, Email, etc.
        //% "Share"
        text: qsTrId("components_contacts-me-share")
        visible: root._contactValid

        onClicked: {
            var content = {
                "data": root.contact.vCard(),
                "name": root._vCardName(root.contact),
                "type": "text/vcard",
                "icon": root.contact.avatarPath.toString()
            }
            pageStack.animatorPush(Qt.resolvedUrl("ContactSharePage.qml"), {"content": content})
        }
    }

    MenuItem {
        //: Edit contact
        //% "Edit"
        text: qsTrId("components_contacts-me-edit")
        visible: root._contactValid

        onClicked: {
            // Ensure we're modifying the canonical instance of this contact
            var c = root.contact.id !== 0 ? root._peopleModel.personById(root.contact.id) : root.contact
            pageStack.animatorPush("ContactEditorDialog.qml", {"subject": c})
        }
    }
}
