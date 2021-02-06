/*
* Copyright (c) 2020 Open Mobile Platform LLC.
*
* License: Proprietary
*/
import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

BackgroundItem {
    id: root

    property alias contactPrimaryName: addressBookItem.contactPrimaryName
    property alias contactSecondaryName: addressBookItem.contactSecondaryName
    property alias addressBook: addressBookItem.addressBook
    property alias icon: buttonIcon

    function animateRemoval() {
        removeComponent.createObject(root, { "target": root })
    }

    width: parent.width
    height: Theme.itemSizeMedium
    opacity: enabled ? 1.0 : Theme.opacityLow

    ContactAddressBookItem {
        id: addressBookItem

        anchors {
            left: parent.left
            right: buttonIcon.left
        }
        rightMargin: Theme.paddingMedium
        opacity: root.opacity
    }

    HighlightImage {
        id: buttonIcon

        anchors {
            verticalCenter: addressBookItem.verticalCenter
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
    }

    Component {
        id: removeComponent

        RemoveAnimation {
            running: true
        }
    }
}
