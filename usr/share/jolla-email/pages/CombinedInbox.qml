/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import com.jolla.email 1.1
import "utils.js" as Utils

Page {
    id: root

    onStatusChanged: {
        if (status === PageStatus.Active) {
            app.coverMode = "mainView"
        }
    }

    EmailMessageListModel {
        id: combinedInboxModel

        folderAccessor: emailAgent.combinedInboxAccessor()
        currentDate: app.today

        onCurrentDateChanged: Utils.updateForDateChange(combinedInboxModel, messageListView)
    }

    Binding {
        target: app
        property: "combinedInboxUnreadCount"
        value: combinedInboxModel.count
    }

    RemorsePopup {
        id: removeSingleRemorse

        function startRemoveSingle(messageId) {
            //% "Deleting mail"
            execute(qsTrId("jolla-email-me-deleting-mail"), function() {
                emailAgent.deleteMessage(messageId)
            })
        }
    }

    MessageRemorsePopup {
        id: multiItemRemoveRemorse
    }

    SilicaListView {
        id: messageListView

        anchors.fill: parent

        PullDownMenu {
            busy: app.syncInProgress

            MenuItem {
                // Defined in message list page
                text: qsTrId("jolla-email-me-select_messages")
                visible: messageListView.count > 0
                onClicked: {
                    pageStack.animatorPush(Qt.resolvedUrl("MultiSelectionPage.qml"), {
                                               removeRemorse: multiItemRemoveRemorse,
                                               selectionModel: combinedInboxModel
                                           })
                }
            }

            MenuItem {
                //: Synchronize inbox of all enabled accounts
                //% "Synchronize all"
                text: qsTrId("jolla-email-me-sync_all")
                onClicked: {
                    emailAgent.accountsSyncAllFolders()
                }
            }

            MenuItem {
                //: New message menu item
                //% "New Message"
                text: qsTrId("jolla-email-me-new_message")
                onClicked: {
                    pageStack.animatorPush(Qt.resolvedUrl("ComposerPage.qml"))
                }
            }
        }

        header: Column {
            width: parent.width
            PageHeader {
                id: pageHeader
                //: Email page header
                //% "Mail"
                title: qsTrId("email-he-email")
            }
            AccountList {
                id: accountList
            }
            Item {
                height: Theme.itemSizeLarge
                width: parent.width
                visible: messageListView.count > 0
                Label {
                    //: Shows overall number of unread messages in the Inboxes of all accounts.
                    //: Takes number of unread messages as a parameter.
                    //% "Inboxes (%1)"
                    text: qsTrId("email-la_unread_messages_in_inboxes").arg(messageListView.count)
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeMedium

                    anchors {
                        baseline: parent.bottom
                        // If possible drop this bottom margin when first item is section header
                        baselineOffset: -Theme.paddingLarge
                        horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            Item {
                height: Math.max(emptyStateText.height + Theme.paddingLarge,
                                 messageListView.height - accountList.height - pageHeader.height - Theme.paddingLarge)
                width: parent.width
                visible: messageListView.count === 0
                Text {
                    id: emptyStateText
                    width: parent.width - 2 * Theme.horizontalPageMargin
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    //: Empty state string for the combined Inboxes list view.
                    //: Shown when none of the Inboxes contain unread messages.
                    //% "No unread emails in Inboxes"
                    text: qsTrId("email-la_no_unread_messages_in_inboxes")
                    font {
                        pixelSize: Theme.fontSizeExtraLarge
                        family: Theme.fontFamilyHeading
                    }
                    color: Theme.secondaryHighlightColor
                }
            }
        }

        footer: Item {
            width: messageListView.width
            height: Theme.paddingLarge
        }

        model: combinedInboxModel

        section {
            property: 'timeSection'

            delegate: SectionHeader {
                text: Format.formatDate(section, Formatter.TimepointSectionRelative)
                height: text === "" ? 0 : Theme.itemSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
            }
        }

        delegate: MessageItem {
            // Hide selected delegates that are under remove threat (i.e. deleted from selection page, not gotten read)
            // Not applicable for single message deletion, it's started from message viewer so it's more or less
            // guaranteed that the main combined inbox model, having only unread messages, doesn't include it.
            hidden: model.selected && multiItemRemoveRemorse.active

            onEmailViewerRequested: {
                pageStack.animatorPush(app.getMessageViewerComponent(), {
                                           "messageId": messageId,
                                           "removeCallback": removeSingleRemorse.startRemoveSingle
                                       })
            }
        }

        VerticalScrollDecorator {}
    }
}
