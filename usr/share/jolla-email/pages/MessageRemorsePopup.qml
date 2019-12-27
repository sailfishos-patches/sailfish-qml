/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1

RemorsePopup {
    property EmailMessageListModel selectionModel

    function startDeleteSelectedMessages() {
        //: Remorse popup for multiple emails deletion
        //% "Deleted %n mail(s)"
        execute(qsTrId("jolla-email-me-deleted-mails", selectionModel.selectedMessageCount),
                function() { selectionModel.deleteSelectedMessages()})
    }

    onCanceled: {
        selectionModel.deselectAllMessages()
    }
}
