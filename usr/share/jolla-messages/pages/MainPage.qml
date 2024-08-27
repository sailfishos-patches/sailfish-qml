/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Messages 1.0
import Nemo.Notifications 1.0
import Nemo.Time 1.0

import "groups"

Page {
    id: mainPage

    property bool showAccountsPlaceholder: !MessageUtils.hasModemOrIMaccounts

    function publishNotification(body) {
        notification.body = body
        notification.publish()
    }

    SilicaListView {
        id: view
        anchors.fill: parent
        model: groupModel
        section.property: "timeSection"
        header: Item { width: parent.width; height: Theme.paddingLarge }
        delegate: Item {
            id: wrapper
            property bool sectionBoundary: ListView.previousSection != ListView.section
            property Item section
            
            height: section === null ? content.height : content.height + section.height
            width: parent.width

            ListView.onRemove: content.animateRemoval(wrapper)

            onSectionBoundaryChanged: {
                if (sectionBoundary) {
                    section = sectionHeader.createObject(wrapper)
                } else {
                    section.destroy()
                    section = null
                }
            }

            GroupDelegate {
                id: content
                y: section ? section.height : 0
                onClicked: mainWindow.showConversation(model.contactGroup)
                currentDateTime: wallClock.time
                groupModel: view.model
            }
        }

        Component {
            id: sectionHeader

            SectionHeader {
                property string section: parent.ListView.section

                text: Format.formatDate(section, Formatter.TimepointSectionRelative)
                height: text.length > 0 ? Theme.itemSizeSmall : 0
            }
        }

        PullDownMenu {
            visible: !mainPage.showAccountsPlaceholder
            MenuItem {
                //% "New message"
                text: qsTrId("messages-me-new_conversation")
                onClicked: mainWindow.newMessage(PageStackAction.Animated)
            }
        }

        ViewPlaceholder {
            // Empty state when SMS is not possible and there are no IM accounts enabled
            //% "No accounts available with messaging functionality. You can add or modify accounts in Settings | Accounts"
            text: mainPage.showAccountsPlaceholder ? qsTrId("messages-la-message-empty_state_accounts")
                                                     // Empty state when there are no messages, but SMS is possible
                                                     //% "Message someone"
                                                   : qsTrId("messages-la-message-someone")
            enabled: view.count === 0
        }

        VerticalScrollDecorator { }
    }

    Notification {
        id: notification

        urgency: Notification.Critical
        isTransient: true
    }

    WallClock {
        id: wallClock
        enabled: Qt.application.active
        updateFrequency: WallClock.Minute
    }
}

