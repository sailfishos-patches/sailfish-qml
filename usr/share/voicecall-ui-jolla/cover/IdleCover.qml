/*
 * Copyright (c) 2012 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.voicecall 1.0
import org.nemomobile.commhistory 1.0
import org.nemomobile.contacts 1.0
import "../common/CallHistory.js" as CallHistory
import "../common"

Item {
    anchors.fill: parent
    visible: !telephony.active && !main.displayDisconnected

    CoverPlaceholder {
        //: Cover placeholder shown when the call log is empty
        //% "Call someone"
        text: telephony.callingPermitted ? qsTrId("voicecall-la-cover_call_someone") : ""
        icon.source: "image://theme/icon-launcher-phone"
        visible: !listView.count
    }

    OpacityRampEffect {
        sourceItem: listView
        offset: 0.5
    }

    ListView {
        id: listView

        interactive: false
        model: main.commCallModel

        width: parent.width
        height: maxItemCount * itemHeight + (headerItem ? headerItem.height : 0)
        y: Theme.paddingMedium + Theme.paddingSmall - (headerItem ? headerItem.height : 0)
        // Add some padding to avoid OpacityRampEffect clipping few pixels from missed call label
        header: Item { width: 1; height: Theme.paddingMedium }

        delegate: Item {
            width: parent.width
            height: itemHeight

            Reminder {
                id: reminder
                phoneNumber: model.remoteUid || ""
                _reminders: Reminders
            }

            CallDirectionIcon {
                id: icon
                x: Theme.paddingMedium
                anchors.verticalCenter: detailsText.verticalCenter
                hasReminder: reminder.exists
                call: model
            }

            CoverLabel {
                id: detailsText

                x: callDirectionIcon.width + 2*icon.x
                y: Theme.paddingSmall
                width: parent.width - x
                person: model.contactIds.length ? people.personById(model.contactIds[0]) : null
                remoteUid: model.remoteUid
            }
        }
    }

    CoverActionList {
        enabled: !telephony.active && telephony.callingPermitted

        CoverAction {
            iconSource: "image://theme/icon-cover-dialer"
            onTriggered: main.mainPage.switchToDialer(TabViewAction.Immediate)
        }
    }
}
