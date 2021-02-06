/****************************************************************************
 **
 ** Copyright (C) 2015 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

Item {
    property bool stickyHeader
    readonly property bool down: layerButton.down || clearNotificationsButton.down || leaveHouseKeepingButton.down
    readonly property bool _housekeeping: Lipstick.compositor.eventsLayer.housekeeping

    function _removeAllNotifications() {
        // make notification items vanish gradually from the bottom to the top of the screen
        var removableItems = []
        notificationList.findMatchingRemovableItems(_itemInView, removableItems)
        feedsList.findMatchingRemovableItems(_itemInView, removableItems)

        var pauseBeforeRemoval = 0
        for (var i=removableItems.length-1; i>=0; i--) {
            if (removableItems[i].pauseBeforeRemoval !== undefined) {
                pauseBeforeRemoval += 150
                removableItems[i].pauseBeforeRemoval = pauseBeforeRemoval
            }
        }

        notificationList.removeAll()
        feedsList.removeAllNotifications()
    }

    function _itemInView(item) {
        var yPos = item.mapToItem(root, 0, 0).y
        return yPos > root.contentY && yPos < root.contentY + root.height
    }

    // Avoid flicker during state switch
    height: Math.max(headerLabel.height, layerButton.height, housekeepingButtons.height) + 2*Theme.paddingMedium
    width: parent.width

    Label {
        id: headerLabel

        //% "Notifications"
        text: qsTrId("lipstick-jolla-home-he-notifications")

        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeLarge
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        truncationMode: TruncationMode.Fade
        width: (_housekeeping ? housekeepingButtons.x : layerButton.x) - x
    }

    IconButton {
        id: layerButton

        onClicked: Lipstick.compositor.eventsLayer.setHousekeeping(true)

        enabled: _housekeepingAllowed && !_housekeeping
        visible: !_housekeeping && !Lipstick.compositor.lockScreenLayer.lockScreenEventsEnabled
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: Theme.paddingMedium
        }
        width: leaveHouseKeepingButton.width
        height: leaveHouseKeepingButton.height

        icon.source: "image://theme/icon-m-levels"

        opacity: !_housekeeping ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {}}

        Rectangle {
            z: -1
            visible: parent.down || stickyHeader
            anchors.fill: parent
            radius: Theme.paddingSmall
            color: parent.down ? Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                               : Theme.rgba(Theme.primaryColor, Theme.opacityFaint)
        }
    }

    Row {
        id: housekeepingButtons

        enabled: _housekeeping
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {}}
        anchors.verticalCenter: parent.verticalCenter

        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: Theme.paddingMedium
        }

        spacing: Theme.paddingMedium

        NotificationHeaderButton {
            id: clearNotificationsButton

            //% "Clear all"
            text: qsTrId("lipstick-jolla-home-bt-clear_all")
            icon.source: "image://theme/icon-splus-delete"

            onClicked: {
                _removeAllNotifications()
                Lipstick.compositor.eventsLayer.setHousekeeping(false)
            }
        }

        NotificationHeaderButton {
            id: leaveHouseKeepingButton

            //% "Exit"
            text: qsTrId("lipstick-jolla-home-bt-exit")
            icon.source: "image://theme/icon-splus-cancel"
            showBackground: true

            // make sure aligns with housekeeping button

            onClicked: Lipstick.compositor.eventsLayer.setHousekeeping(false)
        }
    }
}
