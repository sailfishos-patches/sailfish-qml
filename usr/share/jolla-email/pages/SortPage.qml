/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import "utils.js" as Utils

Page {
    id: root

    property bool isOutgoingFolder

    signal sortSelected(int sortType)

    Component.onCompleted: {
        if (isOutgoingFolder) {
            sortModel.insert(1, {sortType: EmailMessageListModel.Recipients})
        } else {
            sortModel.insert(1, {sortType: EmailMessageListModel.Sender})
        }
    }

    SilicaListView {
        anchors.fill: parent
        model: sortModel

        header: PageHeader {
            //% "Sort by:"
            title: qsTrId("jolla-email-he-sort_by")
        }

        delegate: BackgroundItem {
            Label {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: Utils.sortTypeText(sortType)
                font.pixelSize: Theme.fontSizeMedium
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                elide: Text.ElideRight
            }

            onClicked: root.sortSelected(sortType)
        }
        VerticalScrollDecorator {}
    }

    ListModel {
        id: sortModel

        ListElement {
            sortType: EmailMessageListModel.Time
        }
        ListElement {
            sortType: EmailMessageListModel.Size
        }
        ListElement {
            sortType: EmailMessageListModel.ReadStatus
        }
        ListElement {
            sortType: EmailMessageListModel.Priority
        }
        ListElement {
            sortType: EmailMessageListModel.Attachments
        }
        ListElement {
            sortType: EmailMessageListModel.Subject
        }
    }
}
