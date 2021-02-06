import QtQuick 2.6
import Nemo.Notifications 1.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0 as SailfishContacts
import org.nemomobile.contacts 1.0
import "../"

ListItem {
    id: detailItem

    property string previousDetailType
    property string detailType
    property int detailIndex
    property string detailValue
    property string detailMetadata
    property var detailData
    property var detailActions: []
    readonly property bool _primaryActionAvailable: detailActions.length > 0
    readonly property bool _secondaryActionAvailable: detailActions.length > 1

    signal actionClicked(string actionType)
    signal contentResized(var item, var newItemHeight)

    width: parent.width
    _backgroundColor: "transparent"
    contentHeight: primaryActionBackground.y + primaryActionBackground.height
    onClicked: {
        if (primaryContentLoader.sourceComponent === noteFieldComponent
                && primaryContentLoader.item
                && primaryContentLoader.item.collapsed) {
            primaryContentLoader.item.expand()
        } else if (_primaryActionAvailable) {
            if (detailActions[0].actionType == null || detailActions[0].actionType == undefined) {
                actionNotification.publish()
            } else {
                detailItem.actionClicked(detailActions[0].actionType)
            }
        } else {
            detailItem.actionClicked("")
        }
    }

    Rectangle {
        id: primaryActionBackground
        y: (previousDetailType == detailType || previousDetailType === "") ? 0 : Theme.paddingMedium
        color: detailItem._showPress && !menuOpen ? highlightedColor : "transparent"
        anchors.left: parent.left
        anchors.right: _secondaryActionAvailable ? secondaryActionBackground.left : parent.right
        height: primaryContent.height

        HighlightImage {
            id: primaryActionIcon

            x: Theme.paddingMedium
            y: Theme.paddingSmall
            highlighted: detailItem.highlighted
            source: visible ? detailActions[0].actionIcon
                            : "image://theme/icon-m-clear" // only used for size determination
            visible: detailType != previousDetailType && detailActions.length > 0
            opacity: detailActions.length > 0 && detailActions[0].actionDisabled ? Theme.opacityLow : 1.0
        }

        Column {
            id: primaryContent
            topPadding: Theme.paddingSmall
            bottomPadding: Theme.paddingSmall
            anchors {
                left: primaryActionIcon.right
                right: parent.right
                leftMargin: Theme.paddingMedium
                rightMargin: _secondaryActionAvailable ? Theme.paddingSmall
                                                       : Theme.horizontalPageMargin
            }

            Loader {
                id: primaryContentLoader
                width: parent.width
                sourceComponent: {
                    switch (detailType) {
                    case "address":
                        return addressFieldsComponent
                    case "im":
                        return imFieldsComponent
                    case "note":
                        return noteFieldComponent
                    default:
                        return primaryFieldComponent
                    }
                }
            }
        }
    }

    BackgroundItem {
        id: secondaryActionBackground

        y: primaryActionBackground.y
        anchors.right: parent.right
        height: primaryActionBackground.height
        width: _secondaryActionAvailable ? Theme.paddingMedium + secondaryActionButton.width + secondaryActionButton.anchors.rightMargin
                                         : 0
        visible: _secondaryActionAvailable
        propagateComposedEvents: true
        highlighted: down || menuOpen
        highlightedColor: menuOpen ? "transparent" : detailItem.highlightedColor
        onClicked: {
            if (detailActions[1].actionType == null || detailActions[1].actionType == undefined) {
                actionNotification.publish()
            } else {
                detailItem.actionClicked(detailActions[1].actionType)
            }
        }

        HighlightImage {
            id: secondaryActionButton
            property string iconSource: detailActions.length > 1 ? detailActions[1].actionIcon : ""
            enabled: iconSource.length
            y: Theme.paddingSmall
            anchors.right: parent.right
            anchors.rightMargin: Theme.horizontalPageMargin
            highlighted: secondaryActionBackground.highlighted
            source: iconSource
            opacity: detailActions.length > 1 && detailActions[1].actionDisabled ? Theme.opacityLow : 1.0
        }
    }

    Notification {
        id: actionNotification

        //: Displayed notification if user activates a disabled action
        //% "Operation is currently unavailable"
        summary: qsTrId("components_contacts-la-operation_is_currently_unavailable")
        appIcon: "image://theme/icon-system-warning"
        isTransient: true
    }

    Component {
        id: primaryFieldComponent

        DetailFieldDelegate {
            highlighted: detailItem.highlighted
            value: detailItem.detailValue
            metadata: detailItem.detailMetadata
        }
    }

    Component {
        id: imFieldsComponent

        OnlineAccountDetailFieldDelegate {
            highlighted: detailItem.highlighted
            value: detailItem.detailValue
            metadata: detailItem.detailMetadata
            presenceState: !!detailData.presenceState ? detailData.presenceState : 0
        }
    }

    Component {
        id: noteFieldComponent

        NoteDetailFieldDelegate {
            highlighted: detailItem.highlighted
            value: detailItem.detailValue
            metadata: detailItem.detailMetadata

            onContentResized: detailItem.contentResized(item, newItemHeight)
        }
    }

    Component {
        id: addressFieldsComponent

        Column {
            width: parent.width
            height: implicitHeight + Theme.paddingSmall

            DetailFieldDelegate {
                highlighted: detailItem.highlighted
                value: SailfishContacts.ContactsUtil.getNameForDetailType(Person.AddressType)
                metadata: detailItem.detailMetadata === value ? "" : detailItem.detailMetadata
            }

            DetailFieldDelegate {
                highlighted: detailItem.highlighted
                value: !!detailData.street ? detailData.street : ""
                metadata: SailfishContacts.ContactsUtil.getDescriptionForDetail(Person.AddressType, Person.AddressStreetField)
            }

            DetailFieldDelegate {
                highlighted: detailItem.highlighted
                value: !!detailData.pobox ? detailData.pobox : ""
                metadata: SailfishContacts.ContactsUtil.getDescriptionForDetail(Person.AddressType, Person.AddressPOBoxField)
            }

            DetailFieldDelegate {
                highlighted: detailItem.highlighted
                value: !!detailData.city ? detailData.city : ""
                metadata: SailfishContacts.ContactsUtil.getDescriptionForDetail(Person.AddressType, Person.AddressLocalityField)
            }

            DetailFieldDelegate {
                width: parent.width
                highlighted: detailItem.highlighted
                value: !!detailData.region ? detailData.region : ""
                metadata: SailfishContacts.ContactsUtil.getDescriptionForDetail(Person.AddressType, Person.AddressRegionField)
            }

            DetailFieldDelegate {
                highlighted: detailItem.highlighted
                value: !!detailData.zipcode ? detailData.zipcode : ""
                metadata: SailfishContacts.ContactsUtil.getDescriptionForDetail(Person.AddressType, Person.AddressPostcodeField)
            }

            DetailFieldDelegate {
                highlighted: detailItem.highlighted
                value: !!detailData.country ? detailData.country : ""
                metadata: SailfishContacts.ContactsUtil.getDescriptionForDetail(Person.AddressType, Person.AddressCountryField)
            }
        }
    }
}
