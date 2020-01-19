/****************************************************************************
 **
 ** Copyright (C) 2013-2014 Jolla Ltd.
 ** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
 **
 ****************************************************************************/

import QtQuick 2.5
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1

ListView {
    id: notificationList

    signal clicked
    signal displayed(int id)
    signal expanded(Item item)

    readonly property int maxGroupCount: 4
    readonly property int collapsedCount: Math.min(count, maxGroupCount)
    property QtObject sourceModel
    property bool collapsed
    property bool animateExpansion
    property bool showApplicationName: true
    property bool showCount: true
    property color textColor: Theme.primaryColor
    property string iconSuffix
    property alias notificationLimit: boundedModel.maximumCount
    property bool timestampUpdatesEnabled: true
    property int animationDuration: 250
    readonly property real collapsedNotificationHeight: Theme.fontSizeLarge + Theme.paddingSmall * 2 + Theme.paddingMedium
    readonly property real collapsedHeight: Math.max(collapsedNotificationHeight * collapsedCount, 0)
    readonly property real indicatorWidth: Theme.iconSizeSmall + 2*Theme.paddingLarge

    // This is not the flickable that NotificationItem's context menus should reposition
    property bool __silica_hidden_flickable

    property var _hasRemovableMember: ({})
    property int _hasRemovableMemberTag

    property bool hasRemovableNotifications: _hasRemovableMemberTag, Object.keys(_hasRemovableMember).length > 0

    property bool _removeAllInProgress

    function removeAll() {
        _removeAllInProgress = true
        sourceModel.clearRequested()
        _removeAllInProgress = false
    }

    function findMatchingRemovableItems(filterFunc, matchingResults) {
        return _findMatchingRemovableHeadersAndMembers(notificationList, filterFunc, matchingResults)
    }

    function _findMatchingRemovableHeadersAndMembers(listView, filterFunc, matchingResults) {
        var yPos = listView.contentY
        while (yPos < listView.contentHeight) {
            var item = listView.itemAt(0, yPos)
            if (!item) {
                break
            }
            if (item.userRemovable === true) {
                if (!filterFunc(item)) {
                    return false
                }
                matchingResults.push(item)
                if (item.childNotifications !== undefined) {
                    // this is a header for a list of notifications, so also look through its children
                    // for matching notification member items
                    if (!_findMatchingRemovableHeadersAndMembers(item.childNotifications, filterFunc, matchingResults)) {
                        return false
                    }
                }
            }
            yPos += item.height
        }
        return true
    }

    function _updateHasRemovable(item, removable) {
        var present = item in _hasRemovableMember
        if (removable && !present) {
            _hasRemovableMember[item] = true
            _hasRemovableMemberTag += 1
        } else if (!removable && present) {
            delete _hasRemovableMember[item]
            _hasRemovableMemberTag += 1
        }
    }

    width: parent.width
    displayMarginBeginning: Screen.height
    displayMarginEnd: Screen.height
    interactive: false

    Timer {
        id: refreshTimer
        interval: 60000
        running: timestampUpdatesEnabled
        repeat: true
    }

    model: sourceModel && sourceModel.populated ? boundedModel : null

    BoundedModel {
        id: boundedModel

        model: notificationList.sourceModel

        delegate: Item {
            id: notificationDelegate

            property real _height: notificationItem.height + Theme.paddingMedium

            property alias removableCount: notificationItem.removableCount
            property bool userRemovable: modelData.userRemovable
            property int pauseBeforeRemoval
            property alias childNotifications: notificationItem.notificationListView

            Component.onCompleted: notificationList.displayed(modelData.id)

            width: notificationList.width
            height: _height
            enabled: notificationList.enabled && !notificationList.collapsed

            state: {
                if (!notificationList.collapsed) {
                    return ""
                } else if (notificationList.animateExpansion) {
                    return "animate-from-collapsed"
                } else {
                    return "collapsed"
                }
            }

            states: [
                State {
                    name: "collapsed"
                    PropertyChanges {
                        target: notificationDelegate
                        height: notificationItem.collapsedHeight
                    }
                    PropertyChanges {
                        target: notificationItem
                        collapsed: true
                    }
                }, State {
                    name: "animate-from-collapsed"
                    extend: "collapsed"
                }
            ]
            transitions: Transition {
                from: "animate-from-collapsed"
                to: ""
                SequentialAnimation {
                    SmoothedAnimation {
                        target: notificationDelegate
                        properties: "height"
                        duration: animationDuration
                        velocity: -1
                        easing.type: Easing.InOutQuad
                    }
                    ScriptAction {
                        script: {
                            if (!notificationList.collapsed) {
                                notificationItem.collapsed = false
                            }
                        }
                    }
                }
            }

            NotificationItem {
                id: notificationItem

                indicatorTextColor: notificationList.textColor
                indicatorIconSuffix: notificationList.iconSuffix
                animationDuration: notificationList.animationDuration
                collapsedHeight: notificationList.collapsedNotificationHeight
                showApplicationName: notificationList.showApplicationName
                showCount: notificationList.showCount
                removeAllInProgress: notificationList._removeAllInProgress
                onExpanded: notificationList.expanded(notificationDelegate)

                Connections {
                    target: refreshTimer
                    onTriggered: notificationItem.updateTimestamp()
                    onRunningChanged: if (refreshTimer.running) notificationItem.updateTimestamp()
                }
                Connections {
                    target: object
                    onTimestampChanged: notificationItem.updateTimestamp()
                }

                Component.onCompleted: notificationList._updateHasRemovable(notificationDelegate, hasRemovableMember)
                onHasRemovableMemberChanged: notificationList._updateHasRemovable(notificationDelegate, hasRemovableMember)
            }

            ListView.delayRemove: true
            ListView.onAdd: addAnimation.start()
            ListView.onRemove: {
                notificationDelegate.animatedOpacity = 1
                notificationDelegate.animatedHeight = notificationDelegate._height
                removeAnimation.start()
                notificationList._updateHasRemovable(notificationDelegate, false)
            }

            property real animatedHeight
            property real animatedOpacity

            Binding {
                when: addAnimation.running || removeAnimation.running
                target: notificationDelegate
                property: "height"
                value: notificationDelegate.animatedHeight
            }
            Binding {
                when: addAnimation.running || removeAnimation.running
                target: notificationDelegate
                property: "opacity"
                value: notificationDelegate.animatedOpacity
            }

            NotificationAddAnimation {
                id: addAnimation

                target: notificationDelegate
                heightProperty: "animatedHeight"
                opacityProperty: "animatedOpacity"
                toHeight: notificationDelegate._height
                animationDuration: notificationList.animationDuration
            }

            SequentialAnimation {
                id: removeAnimation

                PauseAnimation {
                    duration: notificationDelegate.pauseBeforeRemoval
                }
                NotificationRemoveAnimation {
                    target: notificationDelegate
                    heightProperty: "animatedHeight"
                    opacityProperty: "animatedOpacity"
                    animationDuration: notificationList.animationDuration
                }
                PropertyAction {
                    target: notificationDelegate
                    property: "ListView.delayRemove"
                    value: false
                }
            }
        }
    }
}
