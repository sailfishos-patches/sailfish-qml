import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0 as Contacts
import org.nemomobile.contacts 1.0

ListItem {
    width: root.width
    height: Theme.itemSizeSmall
    opacity: enabled ? 1.0 : Theme.opacityLow

    property Person person: model.person

    Image {
        id: icon
        x: Theme.horizontalPageMargin - Theme.paddingMedium
        anchors.verticalCenter: parent.verticalCenter
        source: person ? ContactsUtil.syncTargetIcon(person) + "?" + (highlighted ? Theme.highlightColor : Theme.primaryColor)
                       : ""
    }
    Label {
        id: nameLabel
        anchors {
            left: icon.right
            leftMargin: Theme.paddingSmall
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: syncTargetLabel.text !== ""
                                  ? -(syncTargetLabel.implicitHeight/2)
                                  : 0
        }
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
        text: person ? person.displayLabel : ''
    }
    Label {
        id: syncTargetLabel
        anchors {
            left: icon.right
            leftMargin: Theme.paddingSmall
            top: nameLabel.bottom
        }
        text: person ? ContactsUtil.syncTargetDisplayName(person) : ''
        font.pixelSize: Theme.fontSizeExtraSmall
        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
    }
}
