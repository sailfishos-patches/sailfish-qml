/****************************************************************************
 **
 ** Copyright (C) 2015-2020 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1
import "." as Local
import "../main"

Column {
    id: root
    property bool showCount

    readonly property bool hasNotifications: repeater.count > 0

    width: Theme.iconSizeSmall + 2*Theme.paddingLarge

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
                return rv
            }
        }
    }

    Repeater {
        id: repeater
        model: highPriorityModel.populated ? boundedModel : null
    }

    BoundedModel {
        id: boundedModel

        maximumCount: 4
        model: highPriorityModel.populated ? highPriorityModel : null
        delegate: Item {
            width: root.width
            height: Theme.fontSizeLarge + Theme.paddingSmall * 2 + Theme.paddingMedium + Theme.paddingMedium

            NotificationIndicator {
                x: Theme.paddingMedium
                count: modelData.itemCount
                showCount: root.showCount && count > 1
                iconSource: modelData.appIcon
                iconColor: modelData.color
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
