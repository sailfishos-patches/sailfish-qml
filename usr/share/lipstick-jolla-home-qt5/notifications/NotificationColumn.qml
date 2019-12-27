/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Raine Makelainen <raine.makelainen@jolla.com>
**
****************************************************************************/

import QtQuick 2.2
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1
import "." as Local
import "../main"

import org.nemomobile.lipstick 0.1
Item {
    id: root

    property alias iconSuffix: highPriorityList.iconSuffix
    property alias textColor: highPriorityList.textColor
    property alias showApplicationName: highPriorityList.showApplicationName
    property alias showCount: highPriorityList.showCount

    readonly property bool hasNotifications: highPriorityList.count > 0
    property alias spacing: highPriorityList.spacing
    readonly property real targetPosition: 0
    // Reveal indicator width + padding.
    readonly property real margin: Theme.paddingMedium + highPriorityList.indicatorWidth
    readonly property real visiblePosition: -highPriorityList.width + margin

    width: parent.width
    height: highPriorityList.y + highPriorityList.contentHeight

    JollaNotificationGroupModel {
        id: highPriorityModel

        groupProperty: "disambiguatedAppName"
        sourceModel: JollaNotificationListModel {
            filters: {
                var rv = [ {
                    "property": "category",
                    "comparator": "!match",
                    "value": "^x-nemo.system-update"
                }, {
                    "property": "priority",
                    "comparator": ">=",
                    "value": 100
                } ]
                if (Screen.sizeCategory >= Screen.Large) {
                    // Temporary: don't show missed calls on tablet
                    rv.push({
                        "property": "appName",
                        "comparator": "!match",
                        "value": "Missed calls"
                    })
                }
                return rv
            }
        }
    }

    NotificationListView {
        id: highPriorityList

        sourceModel: highPriorityModel.populated ? highPriorityModel : null
        collapsed: true
        height: collapsedHeight
        width: parent.width
        notificationLimit: 4
    }
}
