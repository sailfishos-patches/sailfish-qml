/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    property int messageId
    property alias attachmentsModel: attachmentListView.model

    objectName: "attachmentsListPage"

    SilicaListView {
        id: attachmentListView
        anchors.fill: parent

        header: PageHeader {
            //% "Attachments"
            title: qsTrId("jolla-email-he-attachments_list_page")
        }

        delegate: AttachmentDelegate { }
        VerticalScrollDecorator {}
    }
}
