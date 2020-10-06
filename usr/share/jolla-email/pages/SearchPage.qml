/*
 * Copyright (c) 2015 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import "utils.js" as Utils

Page {
    id: searchPage

    property int accountId
    property string searchString: searchField.text.toLowerCase().trim()
    property bool openingTopPage
    property bool resetSearch

    onSearchStringChanged: messageListModel.setSearch(searchString)

    onStatusChanged: {
        if (status === PageStatus.Deactivating) {
            if (openingTopPage) {
                messageListModel.cancelSearch()
            }
        } else if (status === PageStatus.Active) {
            listView.currentIndex = -1 // To keep focus in a search field after coming back from message viewer
            if (!openingTopPage) {
                searchField.forceActiveFocus()
            }
            // Updating model search options doesn't automatically refresh
            // the search results, so we force it manually here on returning
            if (resetSearch) {
                resetSearch = false
                messageListModel.setSearch(searchString)
            }
            openingTopPage = false
        }
    }

    EmailMessageListModel {
        id: messageListModel

        limit: app.defaultMessageListLimit
        folderAccessor: emailAgent.accountWideSearchAccessor(accountId)
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        currentIndex: -1 // to keep focus

        header: Item {
            width: headerContainer.width
            height: headerContainer.height
        }

        PullDownMenu {
            busy: app.syncInProgress

            MenuItem {
                //% "Search options"
                text: qsTrId("jolla-email-me-search_options")
                onClicked: {
                    openingTopPage = true
                    // TODO: Only reset the search if one of the search options changes
                    resetSearch = true
                    pageStack.animatorPush("SearchOptionsPage.qml", {searchModel: messageListModel})
                }
            }
        }

        model: messageListModel

        section {
            property: 'timeSection'

            delegate: SectionHeader {
                text: Format.formatDate(section, Formatter.TimepointSectionRelative)
                height: text === "" ? 0 : implicitHeight + Theme.itemSizeSmall / 2
                horizontalAlignment: Text.AlignHCenter
            }
        }

        function removeMessage(id) {
            if (currentItem) {
                currentItem.doRemove(id)
            } else {
                console.warn("No current item when deleting searched email")
            }
        }

        delegate: MessageItem {
            searchString: searchPage.searchString
            highlightSender: messageListModel.searchFrom
            highlightRecipients: messageListModel.searchRecipients
            highlightSubject: messageListModel.searchSubject
            highlightBody: messageListModel.searchBody

            // If the user selects the context menu option to move a message, this
            // avoids forcing the active focus to the search field when we return
            onMenuOpenChanged: openingTopPage = menuOpen

            function doRemove(id) {
                if (model.messageId != id) {
                    console.warn("Something went wrong removing an item in search page")
                    return
                }
                remove()
            }

            onEmailViewerRequested: {
                // search model can delete delegates while viewing, workaround by going thru current item
                listView.currentIndex = model.index
                openingTopPage = true
                // TODO: isOutgoing doesn't work for local folders this way, but hard to tell
                // here the "virtual" folder
                pageStack.animatorPush(app.getMessageViewerComponent(), {
                                           "messageId": messageId,
                                           "removeCallback": listView.removeMessage,
                                           "isOutgoing": ((folderId == emailAgent.sentFolderId(accountId))
                                                          || (folderId == emailAgent.draftsFolderId(accountId))
                                                          || (folderId == emailAgent.outboxFolderId(accountId)))
                                       })
            }

            // dismiss keyboard when scrolling
            onPressed: searchField.focus = false
        }

        VerticalScrollDecorator {}

        Column {
            id: headerContainer

            width: searchPage.width
            parent: listView.contentItem
            anchors.top: listView.headerItem ? listView.headerItem.top : listView.top

            PageHeader {
                //% "Search"
                title: qsTrId("jolla-email-he-search")
            }

            SearchField {
                id: searchField

                width: parent.width
                //% "Search emails"
                placeholderText: qsTrId("jolla-components_email-la-search_emails")
                autoScrollEnabled: false
                // avoid removing focus whenever a message is added to the selection list
                focusOutBehavior: FocusBehavior.KeepFocus
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }
        }
    }
}
