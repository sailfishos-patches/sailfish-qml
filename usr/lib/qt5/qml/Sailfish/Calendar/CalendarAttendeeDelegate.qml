import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Sailfish.Contacts 1.0

BackgroundItem {
    id: root

    property string name
    property string email
    property string secondaryText
    property int participationStatus
    property int leftMargin: Theme.horizontalPageMargin
    property int rightMargin: Theme.horizontalPageMargin

    height: extraText.text !== "" ? Theme.itemSizeMedium : Theme.itemSizeExtraSmall

    onClicked: {
        var person = ContactCreator.createContact({"name": root.name, "emailAddresses": [root.email]})
        pageStack.animatorPush("Sailfish.Contacts.ContactCardPage", { contact: person })
    }

    Label {
        id: nameLabel

        x: root.leftMargin
        y: (root.height - height - (extraText.text !== "" ? extraText.height : 0)) / 2

        width: statusIcon.status === Image.Ready
               ? statusIcon.x - Theme.paddingMedium - x
               : root.width - x - root.rightMargin

        truncationMode: TruncationMode.Fade
        text: root.name.length > 0 ? root.name : root.email
    }

    Label {
        id: extraText

        x: root.leftMargin
        y: nameLabel.y + nameLabel.height

        font.pixelSize: Theme.fontSizeSmallBase
        color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
        truncationMode: TruncationMode.Fade
        width: parent.width - x - root.rightMargin
        text: root.secondaryText.length > 0 ? root.secondaryText
                                            : root.name.length > 0 ? root.email
                                                                   : ""
    }

    Icon {
        id: statusIcon

        x: root.width - width - root.rightMargin
        y: nameLabel.y + (nameLabel.height - height) / 2

        source: {
            switch (root.participationStatus) {
            case Person.AcceptedParticipation:
                return "image://theme/icon-s-accept"
            case Person.DeclinedParticipation:
                return "image://theme/icon-s-decline"
            case Person.TentativeParticipation:
                return "image://theme/icon-s-maybe"
            }
            return ""
        }
    }
}
