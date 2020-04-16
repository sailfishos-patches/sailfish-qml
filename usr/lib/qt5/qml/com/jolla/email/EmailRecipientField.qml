/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 – 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0

CompressibleItem {
    id: root

    property alias placeholderText: recipientField.placeholderText
    property alias summaryPlaceholderText: recipientField.summaryPlaceholderText
    property alias summary: recipientField.summary
    property alias contactSearchModel: recipientField.contactSearchModel
    property alias onlineSearchModel: recipientField.onlineSearchModel
    property alias onlineSearchDisplayName: recipientField.onlineSearchDisplayName
    property alias empty: recipientField.empty
    property alias showLabel: recipientField.showLabel

    signal lastFieldExited

    function recipientsToString() {
        return recipientField.recipientsToString()
    }

    function setRecipients(recipients) {
        recipientField.setEmailRecipients(recipients)
    }

    function forceActiveFocus() {
        recipientField.forceActiveFocus()
    }

    function updateSummary() {
        recipientField.updateSummary()
    }

    function saveNewContacts() {
        recipientField.saveNewContacts()
    }

    width: parent.width
    compressible: recipientField.empty
    expandedHeight: recipientField.height

    RecipientField {
        id: recipientField
        visible: !root.compressed
        onLastFieldExited: root.lastFieldExited()
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhEmailCharactersOnly
    }
}
