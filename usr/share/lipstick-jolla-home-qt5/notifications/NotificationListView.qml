/****************************************************************************
 **
 ** Copyright (C) 2013-2017 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
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
    signal collapseMembers

    property QtObject sourceModel

    property bool viewVisible: true

    // This is not the flickable that NotificationStandardGroupItem's context menus should reposition
    property bool __silica_hidden_flickable

    property var _hasRemovableMember: ({})
    property int _hasRemovableMemberTag

    property bool hasRemovableNotifications: _hasRemovableMemberTag, Object.keys(_hasRemovableMember).length > 0

    property bool _removeAllInProgress

    function removeAll() {
        _removeAllInProgress = true
        model.clearRequested()
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
        running: viewVisible
        repeat: true
    }

    delegate: NotificationStandardGroupItem {
        id: delegate

        property int pauseBeforeRemoval
        property bool userRemovable: modelData.userRemovable
        property alias childNotifications: delegate.notificationListView

        onCollapseMembersRequested: notificationList.collapseMembers()

        enabled: notificationList.enabled
        viewVisible: notificationList.viewVisible
        removeAllInProgress: notificationList._removeAllInProgress
        onExpanded: notificationList.expanded(delegate)

        Component.onCompleted: {
            notificationList.displayed(modelData.id)
            notificationList._updateHasRemovable(delegate, hasRemovableMember)
        }
        onHasRemovableMemberChanged: notificationList._updateHasRemovable(delegate, hasRemovableMember)

        Connections {
            target: refreshTimer
            onTriggered: delegate.updateTimestamp()
            onRunningChanged: if (refreshTimer.running) delegate.updateTimestamp()
        }
        Connections {
            target: object
            onTimestampChanged: delegate.updateTimestamp()
        }

        ListView.delayRemove: true
        ListView.onAdd: addAnimation.start()
        ListView.onRemove: {
            delegate.animatedOpacity = 1
            delegate.animatedHeight = delegate.height
            removeAnimation.start()
            notificationList._updateHasRemovable(delegate, false)
        }

        property real animatedHeight
        property real animatedOpacity

        Binding {
            when: addAnimation.running || removeAnimation.running
            target: delegate
            property: "height"
            value: delegate.animatedHeight
        }
        Binding {
            when: addAnimation.running || removeAnimation.running
            target: delegate
            property: "opacity"
            value: delegate.animatedOpacity
        }

        NotificationAddAnimation {
            id: addAnimation

            target: delegate
            heightProperty: "animatedHeight"
            opacityProperty: "animatedOpacity"
            toHeight: delegate.implicitHeight
            onStopped: delegate.height = undefined
        }

        SequentialAnimation {
            id: removeAnimation

            PauseAnimation {
                duration: delegate.pauseBeforeRemoval
            }
            NotificationRemoveAnimation {
                target: delegate
                heightProperty: "animatedHeight"
                opacityProperty: "animatedOpacity"
            }
            PropertyAction {
                target: delegate
                property: "ListView.delayRemove"
                value: false
            }
        }

        Connections {
            target: notificationList
            onCollapseMembers: delegate.collapseMembers()
        }
    }
}
