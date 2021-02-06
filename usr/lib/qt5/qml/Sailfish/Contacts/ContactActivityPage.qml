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

Page {
    id: root

    property var contact
    property bool hidePhoneActions
    property var modelFactory
    property var simManager

    signal startPhoneCall(string number, string modemPath)
    signal startSms(string number)
    signal startInstantMessage(string localUid, string remoteUid)

    SilicaListView {
        id: activityList

        anchors.fill: parent
        opacity: 0
        Behavior on opacity { FadeAnimation {} }

        header: PageHeader {
            id: header

            //% "Activity"
            title: qsTrId("components_contacts-he-activity")
            description: contact.displayLabel
        }

        model: FormattingProxyModel {
            sourceModel: CommRecipientEventModel {
                contactId: root.contact ? root.contact.id : 0
                remoteUid: root.contact && root.contact.id === 0
                           ? SailfishContacts.ContactsUtil.firstPhoneNumber(root.contact)
                           : ""

                onReadyChanged: {
                    if (ready) {
                        // Update opacity here instead of using a binding, as model ready value
                        // starts as true. When contact model loads its events, the change
                        // notify signal is emitted, with the value still being true.
                        activityList.opacity = 1
                    }
                }
            }
            formattedProperties: [ {
                'role': 'endTimeSection',
                'source': 'endTime',
                'formatter': 'formatDate',
                'parameter': Format.TimepointSectionHistorical
            } ]
        }

        section {
            property: 'endTimeSection'

            delegate: SectionHeader {
                text: section
            }
        }

        delegate: ContactActivityDelegate {
            width: parent.width
            leftMargin: Theme.paddingSmall + Theme.iconSizeMedium + Theme.paddingSmall
            simManager: root.simManager
            hidePhoneActions: root.hidePhoneActions
            modelFactory: root.modelFactory
            contact: root.contact

            onStartPhoneCall: root.startPhoneCall(model.remoteUid, modemPath)
            onStartSms: root.startSms(model.remoteUid)
            onStartInstantMessage: root.startInstantMessage(model.localUid, model.remoteUid)
        }

        VerticalScrollDecorator {}
    }
}
