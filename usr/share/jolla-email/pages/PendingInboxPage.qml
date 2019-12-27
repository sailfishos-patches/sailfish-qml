/*
 * Copyright (c) 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import com.jolla.email 1.1

Page {
    id: root

    property int accountId

    onStatusChanged: {
        if (status === PageStatus.Active) {
            tryReplaceWithMessagePage()
        }
    }

    function tryReplaceWithMessagePage() {
        if (root.status != PageStatus.Active)
            return

        var inbox = emailAgent.inboxFolderId(accountId)
        if (inbox > 0) {
            var accessor = emailAgent.accessorFromFolderId(inbox)
            pageStack.replace(Qt.resolvedUrl("MessageListPage.qml"), { folderAccessor: accessor },
                              PageStackAction.Immediate)
        }
    }

    Connections {
        target: emailAgent
        onStandardFoldersCreated: tryReplaceWithMessagePage()
    }

    Column {
        x: Theme.horizontalPageMargin
        width: parent.width - 2*x
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.paddingMedium

        Label {
            //% "Synchronizing account"
            text: qsTrId("jolla-email-la-synchronizing_account")
            anchors.horizontalCenter: parent.horizontalCenter
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
        }
        BusyIndicator {
            running: parent.visible
            size: BusyIndicatorSize.Large
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
