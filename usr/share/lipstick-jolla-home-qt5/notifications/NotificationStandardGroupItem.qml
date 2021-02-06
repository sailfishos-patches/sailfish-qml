/****************************************************************************
 **
 ** Copyright (C) 2013 - 2020 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Lipstick 1.0
import Nemo.DBus 2.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1

NotificationGroupItem {
    id: root

    property alias notificationListView: memberList
    property bool viewVisible: true

    property bool removeAllInProgress
    readonly property bool hasRemovableMember: !!modelData && modelData.hasUserRemovableMembers

    signal expanded
    signal collapseMembers
    signal collapseMembersRequested

    function updateTimestamp() {
        _timestampCounter += 1
    }

    Connections {
        target: Lipstick.compositor.eventsLayer
        onDeactivated: {
            group.collapse()
            collapseMembers()
        }
    }
    onSwipedAway: _notificationGroup.removeRequested()

    readonly property QtObject _notificationGroup: modelData
    property int _timestampCounter
    property int _expansionThreshold: 3
    property int _expansionIncrease: 15

    implicitHeight: column.height
    draggable: groupHeader.draggable

    Column {
        id: column
        width: parent.width

        NotificationGroupHeader {
            id: groupHeader

            name: modelData.appName
            iconSource: modelData.appIcon || ""
            iconColor: modelData.color || ""
            userRemovable: modelData.userRemovable
            extraBackgroundPadding: group.hasOnlyOneItem
            groupHighlighted: root.highlighted
            enabled: false
        }

        Item {
            id: group

            property bool hasOnlyOneItem: modelData.memberCount === 1
            property int excessCount: modelData ? Math.max(modelData.memberCount - boundedNotificationModel.count, 0) : 0
            property int expansionCount
            property int maximumVisibleItemCount: {
                var expandedCount = root._expansionThreshold + expansionCount

                // If we have one more item than the threshold expand automatically because the toggle would use the same space
                if (modelData.memberCount == (expandedCount + 1)) {
                    return expandedCount + 1
                } else {
                    return expandedCount
                }
            }

            width: root.width
            height: memberList.contentHeight

            function expand() {
                expansionCount += root._expansionIncrease
                root.expanded()
            }

            function collapse() {
                expansionCount = 0
            }

            JollaNotificationListModel {
                id: groupMembers
                filterIds: modelData.memberIds
            }

            ListView {
                id: memberList

                property bool __silica_hidden_flickable

                width: parent.width
                height: Screen.height * 1000 // Ensures the view is fully populated without needing to bind height: contentHeight
                model: groupMembers.populated ? boundedNotificationModel : null
                interactive: false

                BoundedModel {
                    id: boundedNotificationModel

                    model: groupMembers
                    maximumCount: group.maximumVisibleItemCount

                    delegate: NotificationStandardGroupMember {
                        id: memberItem

                        onRemoveRequested: notification.removeRequested()
                        onTriggered: notification.actionInvoked("default")

                        onExpand: {
                            if (hasExpandableContent) {
                                root.collapseMembersRequested()
                                expanded = true
                            }
                        }

                        lastItem: model.index === boundedNotificationModel.count - 1

                        notification: modelData
                        userRemovable: modelData.userRemovable

                        contentLeftMargin: groupHeader.textLeftMargin
                        summaryText: notification ? notification.summary : ""
                        bodyText: notification ? notification.body : ""
                        timestampText: notification ? (root._timestampCounter, Format.formatDate(notification.timestamp, Formatter.DurationElapsedShort)) : ""

                        animateContentResizing: boundedNotificationModel.updating
                        animateAddition: defaultAnimateAddition
                        animateRemoval: defaultAnimateRemoval || (root.removeAllInProgress && userRemovable)
                        groupHighlighted: root.highlighted
                        enabled: !housekeeping || !group.hasOnlyOneItem

                        Connections {
                            target: root
                            onCollapseMembers: memberItem.expanded = false
                        }
                    }
                }
            }
        }

        NotificationExpansionButton {
            id: expansionToggle

            expandable: remainingCount > 0
            enabled: expandable && !root.swipeActive && !root.showSwipeHint
            remainingCount: group.excessCount
            onClicked: group.expand()
        }
    }
}
