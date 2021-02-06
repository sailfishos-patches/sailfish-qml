/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import MeeGo.Connman 0.2
import Nemo.Notifications 1.0
import Nemo.DBus 2.0
import Sailfish.Contacts 1.0 as Contacts
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private

Column {
    id: onlineSearch

    property bool active
    property QtObject onlineSearchModel
    property string onlineSearchDisplayName
    property string searchText
    readonly property bool searchable: searchText.length >= onlineSearchModel.minimumCharactersRequired

    // Loose coupling to the EAS GAL Search model
    readonly property bool hasErrorStatus: onlineSearchModel.status === 4
    onHasErrorStatusChanged: if (hasErrorStatus) errorNotification.publish()

    property bool showSearch: true

    height: active ? implicitHeight : 0
    opacity: active ? 1.0 : 0.0
    Behavior on opacity { FadeAnimator {} }
    visible: onlineSearchModel !== null

    onActiveChanged: if (!active) onlineSearchModel.clear()

    onSearchTextChanged: {
        if (searchText.length < onlineSearchModel.minimumCharactersRequired) {
            onlineSearchModel.clear()
        }
        showSearch = true
    }

    function fetchMore() {
        onlineSearchModel.fetchMore()
    }

    function search() {
        onlineSearchModel.search(searchText)
        showSearch = false
    }

    NetworkManager {
        id: networkManager
        readonly property bool online: state == "online"
    }

    DBusInterface {
        id: connectionSelector

        service: "com.jolla.lipstick.ConnectionSelector"
        path: "/"
        iface: "com.jolla.lipstick.ConnectionSelectorIf"
        signalsEnabled: true
        property bool requested

        function open() {
            requested = true
            call('openConnectionNow', '') // wifi + mobile
        }

        function connectionSelectorClosed(connectionSelected) {
            if (requested) {
                requested = false
                if (networkManager.online) onlineSearch.search()
            }
        }
    }

    SectionHeader {
        //: Shown as a section header for online address book.
        //% "Online address book"
        text: qsTrId("components_contacts-he-online_address_book")
    }

    ColumnView {
        id: searchList

        itemHeight: Theme.itemSizeSmall
        model: onlineSearchModel
        width: onlineSearch.width

        delegate: BackgroundItem {
            id: onlineContactItem

            width: onlineSearch.width
            height: isPortrait ? Theme.itemSizeSmall : Theme.itemSizeExtraSmall

            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: Theme.horizontalPageMargin
                    rightMargin: Theme.horizontalPageMargin
                }
                truncationMode: TruncationMode.Fade
                textFormat: Text.StyledText
                text: Theme.highlightText(model.displayName, searchText, Theme.highlightColor)
                color: onlineContactItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            onClicked: {
                var contactData = onlineSearchModel.getContact(index)
                contactData.accountId = onlineSearchModel.accountId
                updateFromKnownContact(contactData,
                                       model.displayName, model.emailAddress)
                onlineSearchModel.clear()
            }
        }
    }

    BackgroundItem {
        id: searchButton

        height: Math.max(isPortrait ? Theme.itemSizeSmall : Theme.itemSizeExtraSmall,
                         searchIcon.height + 2 * Theme.paddingSmall,
                         searchLabel.height + 2 * Theme.paddingSmall)

        enabled: active && searchable && !searchIndicator.running
        visible: !showMore.visible && showSearch && !searchIndicator.running

        onClicked: {
            if (networkManager.online) search()
            else connectionSelector.open()
        }

        Icon {
            id: searchIcon

            anchors.verticalCenter: parent.verticalCenter
            source: hasErrorStatus ? "image://theme/icon-m-refresh" : "image://theme/icon-m-search"
            x: Theme.horizontalPageMargin
            highlighted: !searchable || searchButton.down
        }

        Label {
            id: searchLabel

            anchors {
                left: searchIcon.right
                leftMargin: Theme.paddingMedium
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
            }
            highlighted: searchIcon.highlighted
            text: {
                if (!searchable) {
                    //: Enter more characters to search from online address book
                    //: is shown until enough characters are shown.
                    //% "Enter more characters"
                    return qsTrId("components_contacts-la-enter_more_characters")
                } else if (!hasErrorStatus) {
                    //: Extend contact search to online sources.
                    //% "Search"
                    return qsTrId("components_contacts-la-search_online_address_book")
                } else {
                    //: Try searching online sources after a failure
                    //% "Retry"
                    return qsTrId("components_contacts-la-retry_online_address_book_search")
                }
            }

            truncationMode: TruncationMode.Fade
        }

        Label {
            id: searchDescription

            height: visible ? (implicitHeight + Theme.paddingMedium) : 0
            anchors.top: searchLabel.bottom
            anchors.left: searchLabel.left
            anchors.right: searchLabel.right
            text: onlineSearchDisplayName
            font.pixelSize: Theme.fontSizeExtraSmall
            color: searchIcon.highlighted ? searchLabel.palette.secondaryHighlightColor : searchLabel.palette.secondaryColor
            truncationMode: TruncationMode.Fade
        }
    }

    BusyIndicator {
        id: searchIndicator

        // Reserve same height as for Search button to avoid unwanted height animations
        height: searchButton.height
        anchors.horizontalCenter: parent.horizontalCenter
        visible: running
        running: onlineSearchModel.busy
    }

    BackgroundItem {
        id: showMore

        enabled: onlineSearchModel.hasMore
        height: isPortrait ? Theme.itemSizeSmall : Theme.itemSizeExtraSmall
        visible: enabled && !searchIndicator.running && !showSearch

        onClicked: fetchMore()

        Private.ShowMoreButton {
            anchors.verticalCenter: parent.verticalCenter
            enabled: false
            highlighted: showMore.highlighted
            width: parent.width - 2 * x
            x: Theme.horizontalPageMargin
        }
    }

    Notification {
        id: errorNotification

        //: Displayed notification if online search fails
        //% "Failed to extend search to online address book"
        summary: qsTrId("components_contacts-la-failed_to_extend_search_to_online_address_book")
        appIcon: "image://theme/icon-system-warning"
        isTransient: true
    }
}
