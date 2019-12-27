/****************************************************************************
**
** Copyright (C) 2013-2014 Jolla Ltd.
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1
import org.nemomobile.time 1.0
import org.nemomobile.configuration 1.0
import "../lockscreen"
import "../notifications" as Notifications
import "weather"
import "../main"
import "calendar"

SilicaFlickable {
    id: root

    property bool collapsed: true
    property real statusBarHeight
    readonly property bool hasNotifications: notificationList.count > 0 || systemUpdateList.count > 0 || feedsList.hasVisibleFeeds
    property int animationDuration
    property alias headerItem: headerColumn
    property real defaultNotificationAreaY: headerColumn.y + headerColumn.height + Theme.paddingMedium
    property bool menuOpen: pullDownMenu != null && pullDownMenu.active

    property bool _housekeepingAllowed: (notificationListModel.populated && notificationList.hasRemovableNotifications)
                        || feedsList.hasRemovableNotifications

    contentHeight: Math.ceil(Math.max(footerSpacer.y + footerSpacer.height, noNotificationsLabel.y + noNotificationsLabel.height))

    function collapse() {
        positioningAnimation.complete()
        root.collapsed = true
    }

    function expand(animate) {
        positioningBehavior.enabled = animate
        root.collapsed = false
        positioningBehavior.enabled = false
    }

    function _scrollToExpandingItem(item, yOffset) {
        expandingItemConn.targetYOffset = yOffset
        expandingItemConn.target = item
    }

    on_HousekeepingAllowedChanged: {
        Lipstick.compositor.eventsLayer.housekeepingAllowed = _housekeepingAllowed
    }

    Connections {
        id: expandingItemConn
        property real targetYOffset

        onHeightChanged: {
            var targetTopY = root.contentItem.mapFromItem(target, 0, 0).y
            var targetBottomY = targetTopY + target.height
            if (targetBottomY < root.contentY + root.height) {
                return
            }
            scrollBehavior.enabled = true
            root.contentY = Math.min(targetTopY + targetYOffset, targetBottomY - root.height)
        }
    }

    Behavior on contentY {
        id: scrollBehavior
        enabled: false

        SequentialAnimation {
            NumberAnimation {
                duration: notificationList.animationDuration * 2
                easing.type: Easing.InOutQuad
            }
            ScriptAction {
                script: {
                    scrollBehavior.enabled = false
                    if (expandingItemConn.target.height > root.height) {
                        scrollDecorator.showDecorator()
                    }
                    expandingItemConn.target = null
                    expandingItemConn.targetYOffset = 0
                }
            }
        }
    }

    JollaNotificationGroupModel {
        id: notificationListModel

        function markAsDisplayed(ids) {
            sourceModel.markAsDisplayed(ids)
        }

        groupProperty: "disambiguatedAppName"
        sourceModel: JollaNotificationListModel {
            filters: [ {
                "property": "category",
                "comparator": "!match",
                "value": "^x-nemo.system-update"
            } ]
        }
    }

    JollaNotificationGroupModel {
        id: systemUpdateListModel

        groupProperty: "disambiguatedAppName"
        sourceModel: JollaNotificationListModel {
            filters: [ {
                "property": "category",
                "comparator": "match",
                "value": "^x-nemo.system-update"
            } ]
        }
    }

    Column {
        id: headerColumn

        width: parent.width

        // Leave space for the status area
        y: statusBarHeight + Theme.paddingMedium

        spacing: Theme.paddingSmall

        opacity: collapsed ? 0.0 : 1.0
        Behavior on opacity {
            enabled: hasNotifications
            FadeAnimation { duration: animationDuration }
        }

        WeatherLoader {
            id: weatherWidget
            active: false
        }

        Label {
            id: dateLabel

            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                var dateString = Format.formatDate(wallClock.time, Format.DateFull)
                return dateString.charAt(0).toUpperCase() + dateString.substr(1)
            }
            color: Theme.highlightColor
            font {
                pixelSize: Theme.fontSizeExtraSmall
                family: Theme.fontFamilyHeading
            }
            WallClock {
                id: wallClock
                enabled: Desktop.eventsViewVisible
                updateFrequency: WallClock.Day
            }
        }

        // For future use:
        //EventsViewSystemUpdate {}

        Item { height: Theme.paddingSmall; width: parent.width }

        CalendarWidgetLoader {
            id: calendarWidget
            active: false
            eventsView: root
        }

        ConfigurationValue {
            id: eventsScreenWidgets

            key: "/desktop/lipstick-jolla-home/events_screen_widgets"

            // The default value should match the defaults set in the
            // /usr/share/lipstick/eventswidgets/*.json files
            defaultValue: [
                "/usr/share/lipstick-jolla-home-qt5/eventsview/weather/WeatherLoader.qml",
                "/usr/share/lipstick-jolla-home-qt5/eventsview/calendar/CalendarWidgetLoader.qml"
            ]

            onValueChanged: update()
            Component.onCompleted: update()

            function update() {
                var weatherUrl = Qt.resolvedUrl("weather/WeatherLoader.qml")
                var calendarUrl = Qt.resolvedUrl("calendar/CalendarWidgetLoader.qml")

                var weatherEnabled = false
                var calendarEnabled = false

                for (var i = 0; i < value.length; ++i) {
                    var url = Qt.resolvedUrl(value[i])
                    if (url === weatherUrl) {
                        weatherEnabled = true
                    } else if (url === calendarUrl) {
                        calendarEnabled = true
                    }
                }

                weatherWidget.active = weatherEnabled
                calendarWidget.active = calendarEnabled
            }
        }
    }

    InfoLabel {
        id: noNotificationsLabel

        x: notificationsArea.x + Theme.paddingMedium
        y: Math.max(headerColumn.y + headerColumn.height + Theme.paddingLarge, root.height/2 - implicitHeight/2)
        width: notificationsArea.width - 2*Theme.paddingMedium
        opacity: (!root.hasNotifications && notificationList.contentHeight < 1 && !feedsList.showingRemovableContent)
                 ? 1.0 : 0.0

        //% "You don't have any notifications right now"
        text: qsTrId("lipstick-jolla-home-la-you_dont_have_any_notifications")
        height: opacity > 0 ? implicitHeight + Theme.paddingLarge : 0

        Behavior on opacity { FadeAnimation { duration: 300 } }
    }

    Item {
        id: notificationsArea

        width: parent.width
        height: Math.max(systemUpdateList.contentHeight + notificationList.contentHeight + feedsList.height, root.height - y)

        y: {
            if (!root.collapsed || !root.hasNotifications) {
                return defaultNotificationAreaY
            }

            // Header column fades in when collapsed changes to false. No need to take
            // that into account over here.

            // Calculate the amount of space needed to place the collapsed list body in the
            // vertical center of the view, to align with the lock screen, which only shows
            // high-priority notifications and not system-update notifications
            var collapsedHeight = Lipstick.compositor.notificationOverviewLayer.notificationColumn.height
            return (root.height - collapsedHeight)/2 - systemUpdateList.contentHeight
        }

        Behavior on y {
            id: positioningBehavior
            NumberAnimation {
                id: positioningAnimation
                duration: root.animationDuration
                easing.type: Easing.InOutQuad
            }
        }

        InverseMouseArea {
            anchors.fill: notificationsArea
            enabled: Lipstick.compositor.eventsLayer.housekeeping && !pullDownMenu.active
            onClickedOutside: Lipstick.compositor.eventsLayer.setHousekeeping(false)
        }

        MouseArea {
            objectName: "EventsViewList_housekeeping"
            anchors.fill: parent
            onPressAndHold: Lipstick.compositor.eventsLayer.toggleHousekeeping()
            onClicked: Lipstick.compositor.eventsLayer.setHousekeeping(false)
        }

        Notifications.NotificationListView {
            id: systemUpdateList

            height: Screen.height * 1000 // Ensures the view is fully populated without needing to bind height: contentHeight
            sourceModel: systemUpdateListModel.populated ? systemUpdateListModel : null
            timestampUpdatesEnabled: Desktop.eventsViewVisible
            animationDuration: root.animationDuration
            collapsed: root.collapsed
            animateExpansion: positioningBehavior.enabled
        }

        Notifications.NotificationListView {
            id: notificationList

            property var displayedIds: ({})
            onDisplayed: displayedIds[id] = true
            onExpanded: root._scrollToExpandingItem(item, 0)

            Connections {
                target: Lipstick.compositor.eventsLayer
                onActiveChanged: {
                    if (!Lipstick.compositor.eventsLayer.active) {
                        var ids = []
                        for (var id in notificationList.displayedIds) {
                            ids.push(id)
                        }
                        notificationListModel.markAsDisplayed(ids)
                        notificationList.displayedIds = {}
                    }
                }
            }

            // Do not overwrite/break width binding
            height: Screen.height * 1000 // Ensures the view is fully populated without needing to bind height: contentHeight
            y: systemUpdateList.contentHeight
            sourceModel: notificationListModel.populated ? notificationListModel : null
            timestampUpdatesEnabled: Desktop.eventsViewVisible
            animationDuration: root.animationDuration
            collapsed: root.collapsed
            animateExpansion: positioningBehavior.enabled
        }

        EventFeedList {
            id: feedsList
            y: systemUpdateList.contentHeight + notificationList.contentHeight
            collapsed: root.collapsed
            animationDuration: root.animationDuration
            onExpanded: root._scrollToExpandingItem(item, itemYOffset)
            Binding on width {
                when: Desktop.eventsViewVisible || Lipstick.compositor.lockScreenLayer.exposed
                value: notificationList.width
            }
        }
    }

    Item {
        id: footerSpacer
        y: notificationsArea.y + notificationsArea.height
        visible: root.hasNotifications

        // Only include footer spacing if the content above exceeds the available height
        height: y > root.height ? Theme.itemSizeSmall : 0
        Behavior on height {
            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.InOutQuad
            }
        }
    }

    VerticalScrollDecorator { id: scrollDecorator }

    PullDownMenu {
        id: pullDownMenu
        property bool clearNotificationsWhenClosed

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

        visible: Lipstick.compositor.eventsLayer.housekeeping

        MenuItem {
            //% "Clear notifications"
            text: qsTrId("lipstick-jolla-home-me-clear_notifications")
            onClicked: pullDownMenu.clearNotificationsWhenClosed = true
        }

        onActiveChanged: {
            if (!active && clearNotificationsWhenClosed) {
                pullDownMenu._removeAllNotifications()
                clearNotificationsWhenClosed = false
                Lipstick.compositor.eventsLayer.setHousekeeping(false)
            }
        }
    }

    // Block mouse / touch events when positioning animation is enabled.
    MouseArea {
        objectName: "EventsViewList_blocker"
        anchors.fill: parent
        enabled: positioningAnimation.running
    }
}
