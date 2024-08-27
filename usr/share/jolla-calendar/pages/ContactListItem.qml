import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0 as Contacts

ListItem {
    id: root

    property string searchText

    contentHeight: content.height + 2*Theme.paddingSmall

    function getEmailText(emailDetails) {
        if (!emailDetails || emailDetails.length === 0) {
            return ""
        }

        emailDetails = Contacts.Person.removeDuplicateEmailAddresses(emailDetails)
        if (emailDetails.length > 1) {
            var addressString = emailDetails[0].address
            for (var i = 0; i < emailDetails.length; ++i) {
                if (emailDetails[i].address.indexOf(searchText.toLocaleLowerCase()) > -1) {
                    addressString = Theme.highlightText(emailDetails[i].address, searchText, Theme.highlightColor)
                    break
                }
            }

            //: %1 replaced with best match email and %n tells how many other addresses this contact has
            //% "%1 + %n other"
            return qsTrId("calendar-other_click_to_select", emailDetails.length - 1).arg(addressString)
        } else {
            return Theme.highlightText(emailDetails[0].address, searchText, Theme.highlightColor)
        }
    }

    Column {
        id: content

        x: Theme.horizontalPageMargin
        width: parent.width - 2*x
        anchors.verticalCenter: parent.verticalCenter

        Label {
            width: parent.width
            text: Theme.highlightText(displayLabel, searchText, Theme.highlightColor)
            textFormat: Text.StyledText
            truncationMode: TruncationMode.Fade
            color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
        Label {
            width: parent.width
            text: getEmailText(emailDetails)
            font.pixelSize: Theme.fontSizeTiny
            textFormat: Text.StyledText
            truncationMode: TruncationMode.Fade
            color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }
    }
}
