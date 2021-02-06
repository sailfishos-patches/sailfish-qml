/*
 * Copyright (c) 2013 - 2019 Jolla Pty Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0 as SailfishContacts
import Sailfish.Telephony 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.commhistory 1.0

Column {
    id: root

    property Person contact
    property var modelFactory
    property bool hidePhoneActions
    property date today
    property var simManager

    property int limit
    property int reducedLimit
    property bool reduced

    readonly property bool ready: contactEventModel.ready
    readonly property bool hasMore: limit > 0 && count >= limit
    property alias count: activityRepeater.count

    signal startPhoneCall(string number, string modemPath)
    signal startSms(string number)
    signal startInstantMessage(string localUid, string remoteUid)

    width: parent.width

    Repeater {
        id: activityRepeater

        model: contactEventModel

        delegate: ContactActivityDelegate {
            width: parent.width
            simManager: root.simManager
            hidePhoneActions: root.hidePhoneActions
            modelFactory: root.modelFactory
            contact: root.contact
            showYear: model.endTime.getFullYear() !== root.today.getFullYear()

            visible: (root.limit <= 0 || index < root.limit)
                     && (!root.reduced || root.reducedLimit <= 0 || index < root.reducedLimit)

            onStartPhoneCall: root.startPhoneCall(model.remoteUid, modemPath)
            onStartSms: root.startSms(model.remoteUid)
            onStartInstantMessage: root.startInstantMessage(model.localUid, model.remoteUid)
        }
    }

    CommRecipientEventModel {
        id: contactEventModel

        contactId: root.contact ? root.contact.id : 0
        remoteUid: root.contact && root.contact.id === 0
                   ? SailfishContacts.ContactsUtil.firstPhoneNumber(root.contact)
                   : ""
        limit: root.limit > 0 ? root.limit : 0
    }
}
