/****************************************************************************
 **
 ** Copyright (C) 2013-2018 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
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

    property real statusBarHeight
    readonly property bool hasNotifications: notificationList.count > 0 || systemUpdateList.count > 0 || feedsList.hasVisibleFeeds
    property bool stickyHeader: !Lipstick.compositor.lockScreenLayer.lockScreenEventsEnabled
                                && contentY > notificationsArea.y + notificationHeaderContainer.y + notificationHeader.height

    property bool _housekeepingAllowed: !Lipstick.compositor.lockScreenLayer.lockScreenEventsEnabled &&
                                        ((notificationListModel.populated && notificationList.hasRemovableNotifications)
                                         || feedsList.hasRemovableNotifications)

    contentHeight: Math.ceil(Math.max(footerSpacer.y + footerSpacer.height, noNotificationsLabel.y + noNotificationsLabel.height)) + Theme.paddingLarge
    topMargin: -notificationHeader.height
    clip: stickyHeader

    function _scrollToExpandingItem(item, yOffset) {
        expandingItemConn.targetYOffset = yOffset
        expandingItemConn.target = item
    }

    on_HousekeepingAllowedChanged: {
        Lipstick.compositor.eventsLayer.housekeepingAllowed = _housekeepingAllowed
        Lipstick.compositor.eventsLayer.setHousekeeping(false)
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
            NumberAnimation { duration: 400; easing.type: Easing.InOutQuad }
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
                }
            ]
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
                }
            ]
        }
    }

    Column {
        id: headerColumn

        // Leave space for the status area
        y: statusBarHeight - Theme.paddingSmall
        spacing: Theme.paddingSmall
        width: parent.width

        Label {
            id: dateLabel

            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                var dateString = Format.formatDate(wallClock.time, Format.DateFull)
                return dateString.charAt(0).toUpperCase() + dateString.substr(1)
            }
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeSmall
            WallClock {
                id: wallClock
                enabled: Desktop.eventsViewVisible
                updateFrequency: WallClock.Day
            }
        }

        WeatherLoader {
            id: weatherWidget
            active: false
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
        y: Math.max(notificationsArea.y + notificationHeaderContainer.y + notificationHeader.height + Theme.itemSizeSmall,
                    root.height/2 - implicitHeight/2)
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
        height: Math.max(systemUpdateList.contentHeight + notificationList.contentHeight + notificationHeader.height + feedsList.height, root.height - y)

        anchors {
            top: headerColumn.bottom
            topMargin: Theme.paddingMedium
        }

        InverseMouseArea {
            anchors.fill: notificationsArea
            enabled: Lipstick.compositor.eventsLayer.housekeeping && !notificationHeader.down
            onClickedOutside: Lipstick.compositor.eventsLayer.setHousekeeping(false)
        }

        MouseArea {
            objectName: "EventsViewList_housekeeping"
            anchors.fill: parent
            enabled: Lipstick.compositor.eventsLayer.housekeepingAllowed
            onPressAndHold: if (!Lipstick.compositor.eventsLayer.housekeeping) Lipstick.compositor.eventsLayer.setHousekeeping(true)
            onClicked: Lipstick.compositor.eventsLayer.setHousekeeping(false)
        }

        Item {
            id: notificationHeaderContainer

            height: notificationHeader.height
            width: parent.width

            Notifications.NotificationHeader {
                id: notificationHeader
                stickyHeader: root.stickyHeader
                parent: stickyHeader ? root.parent : notificationHeaderContainer
            }
        }

        Notifications.NotificationListView {
            id: systemUpdateList

            y: notificationHeaderContainer.height
            height: Screen.height * 1000 // Ensures the view is fully populated without needing to bind height: contentHeight
            model: systemUpdateListModel.populated ? systemUpdateListModel : null
            viewVisible: Desktop.eventsViewVisible
        }

        Notifications.NotificationListView {
            id: notificationList

            property var displayedIds: ({})
            onDisplayed: displayedIds[id] = true
            onExpanded: root._scrollToExpandingItem(item, 0)

            y: systemUpdateList.y + systemUpdateList.contentHeight

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
            model: notificationListModel.populated ? notificationListModel : null
            viewVisible: Desktop.eventsViewVisible
        }

        EventFeedList {
            id: feedsList
            y: notificationList.y + notificationList.contentHeight
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
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
    }

    VerticalScrollDecorator {
        id: scrollDecorator
        _forcedParent: root.parent
        _topMenuSpacing: root.topMargin
    }
}
