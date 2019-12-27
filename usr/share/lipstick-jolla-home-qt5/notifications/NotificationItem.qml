/****************************************************************************
 **
 ** Copyright (C) 2013-2014 Jolla Ltd.
 ** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
 **
 ****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Nemo.DBus 2.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1

Item {
    id: root

    property alias showApplicationName: groupHeader.showName
    property alias showCount: groupHeader.showTotalItemCount
    property color indicatorTextColor
    property string indicatorIconSuffix

    property bool collapsed
    property alias collapsedHeight: groupHeader.height
    property int animationDuration: 250
    property alias notificationListView: memberList

    property bool removeAllInProgress
    property bool hasRemovableMember: removableCount > 0
    property int removableCount: modelData ? Math.min(modelData.removableMemberCount, memberList.count) : 0

    signal expanded

    function updateTimestamp() {
        _timestampCounter += 1
    }


    property QtObject _notificationGroup: modelData
    property int _timestampCounter
    property int _expansionThreshold: 3
    property int _expansionMaximum: 15

    function _invokeAppAction() {
        // Invoke the 'app' action directly
        var remoteActions = root._notificationGroup.remoteActions
        for (var i = 0; i < remoteActions.length; ++i) {
            if (remoteActions[i].name == "app") {
                RemoteAction.invoke(
                            remoteActions[i].service,
                            remoteActions[i].path,
                            remoteActions[i].iface,
                            remoteActions[i].method,
                            remoteActions[i].arguments)
                break
            }
        }
    }

    width: parent.width
    height: group.y + group.height

    NotificationGroupHeader {
        id: groupHeader

        name: modelData.appName
        indicator.iconSource: modelData.appIcon || modelData.icon
        indicator.textColor: root.indicatorTextColor
        indicator.iconSuffix: root.indicatorIconSuffix
        memberCount: modelData.memberCount
        totalItemCount: modelData.itemCount

        userRemovable: modelData.userRemovable
        animationDuration: root.animationDuration

        enabled: {
            if (!collapsed) {
                if (root._notificationGroup) {
                    var remoteActions = root._notificationGroup.remoteActions
                    for (var i = 0; i < remoteActions.length; ++i) {
                        if (remoteActions[i].name == "app") {
                            return true
                        }
                    }
                }
            }
            return false
        }

        onRemoveRequested: {
            root._notificationGroup.removeRequested()
        }

        onTriggered: {
            if (!root._notificationGroup || !root._notificationGroup.members.length) {
                return
            }
            root._invokeAppAction()
        }
    }

    Item {
        id: group

        // If we have one more item than the threshold expand automatically because the toggle would use the same space
        property bool manuallyExpanded
        property bool autoExpanded: modelData.memberCount == (root._expansionThreshold + 1)
        property int unseenCount: modelData && (autoExpanded || manuallyExpanded) ? Math.max(modelData.memberCount - memberList.count, 0) : 0
        property int excessCount: Math.max(modelData.memberCount - root._expansionThreshold, 0)
        property bool expandable: !manuallyExpanded && !autoExpanded && excessCount > 0

        width: root.width
        y: groupHeader.height
        height: collapsed ? 0 : memberList.contentHeight + expansionToggle.height + moreItem.height
        opacity: collapsed ? 0 : 1

        Behavior on opacity {
            FadeAnimation {
                duration: animationDuration
            }
        }

        Connections {
            target: root
            onCollapsedChanged: {
                if (root.collapsed) {
                    group.manuallyExpanded = false
                }
            }
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
            interactive: false

            model: groupMembers.populated ? boundedNotificationModel : null

            BoundedModel {
                id: boundedNotificationModel

                maximumCount: group.autoExpanded || group.manuallyExpanded ? root._expansionMaximum : root._expansionThreshold

                model: groupMembers

                delegate: NotificationStandardGroupMember {
                    id: memberItem

                    notification: modelData
                    userRemovable: modelData.userRemovable

                    // Fallback to preview values if summary or body is not present
                    summaryText: notification ? (notification.summary || notification.previewSummary) : ""
                    bodyText: notification ? (notification.body || notification.previewBody) : ""
                    timestampText: notification ? (root._timestampCounter, Format.formatDate(notification.timestamp, Formatter.DurationElapsedShort)) : ""

                    contentWidth: width - contentLeftMargin - Theme.paddingLarge*2
                    animateContentResizing: boundedNotificationModel.updating
                    animateAddition: !root.collapsed && defaultAnimateAddition
                    animateRemoval: (!root.collapsed && defaultAnimateRemoval) || (root.removeAllInProgress && userRemovable)
                    animationDuration: root.animationDuration

                    onRemoveRequested: {
                        notification.removeRequested()
                    }

                    onTriggered: {
                        notification.actionInvoked("default")
                    }
                }
            }
        }

        NotificationExpansionButton {
            id: expansionToggle
            y: memberList.y + memberList.contentHeight

            expandable: group.expandable
            inRemovableGroup: modelData.userRemovable
            animationDuration: root.animationDuration

            onClicked: {
                group.manuallyExpanded = true
                root.expanded()
            }
        }

        BackgroundItem {
            id: moreItem
            x: expansionToggle.x
            y: expansionToggle.y + expansionToggle.height
            height: {
                var expandedHeight = seeMore.height + 2*Theme.paddingMedium
                return expandedHeight * opacity
            }
            opacity: group.unseenCount > 0 ? 1 : 0
            Behavior on opacity {
                FadeAnimation {
                    duration: animationDuration
                }
            }

            Label {
                id: seeMore

                anchors {
                    top: parent.top
                    topMargin: Theme.paddingMedium
                    left: parent.left
                    leftMargin: expansionToggle.contentLeftMargin
                }
                //: Prompt to see all notifications in the associated app
                //% "See %1 more"
                text: qsTrId("lipstick-jolla-home-la-see-n-more").arg(Math.max(group.unseenCount, 1))
                font.pixelSize: Theme.fontSizeExtraSmall
                font.italic: true
                color: expansionToggle.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }

            onClicked: root._invokeAppAction()
        }
    }
}
