/****************************************************************************
 **
 ** Copyright (C) 2013-2019 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1

Column {
    id: column

    property bool hasVisibleFeeds: height > 0
    property bool hasRemovableNotifications
    property bool showingRemovableContent   // will be true if there are no notifications, but removal animations are still running

    signal expanded(Item item, real itemYOffset)

    function findMatchingRemovableItems(filterFunc, matchingResults) {
        for (var i=0; i<eventFeedList.count; i++) {
            var loader = eventFeedList.itemAt(i)
            if (loader.status == Loader.Ready) {
                loader.item.findMatchingRemovableItems(filterFunc, matchingResults)
            }
        }
    }

    function removeAllNotifications() {
        for (var i=0; i<eventFeedList.count; i++) {
            var loader = eventFeedList.itemAt(i)
            if (loader.status == Loader.Ready) {
                loader.item.removeAllNotifications()
            }
        }
    }

    function _reloadHasRemovableNotifications() {
        for (var i=0; i<eventFeedList.count; i++) {
            if (!eventFeedList.itemAt(i) || eventFeedList.itemAt(i).status != Loader.Ready) {
                continue
            }
            var loadedItem = eventFeedList.itemAt(i).item
            if (loadedItem.hasRemovableItems) {
                hasRemovableNotifications = true
                return
            }
        }
        hasRemovableNotifications = false
    }

    function _reloadShowingRemovableContent() {
        for (var i=0; i<eventFeedList.count; i++) {
            if (!eventFeedList.itemAt(i) || eventFeedList.itemAt(i).status != Loader.Ready) {
                continue
            }
            var loadedItem = eventFeedList.itemAt(i).item
            if (loadedItem.userRemovable && loadedItem.mainContentHeight > 0) {
                showingRemovableContent = true
                return
            }
        }
        showingRemovableContent = false
    }

    Loader {
        id: eventFeedListModel

        // EventFeedSocialSubviewModel requires EventFeedAccountManager
        // which requires Sailfish.Accounts.
        Component.onCompleted: {
            setSource(Qt.resolvedUrl("EventFeedSocialSubviewModel.qml"), {
                          "manager": Qt.binding(function() { return accountManager.item })
                      })
        }
    }

    Loader {
        id: accountManager

        // Handle Sailfish.Accounts dependency during runtime.
        Component.onCompleted: setSource(Qt.resolvedUrl("EventFeedAccountManager.qml"))
    }

    Repeater {
        id: eventFeedList
        model: eventFeedListModel.item ? eventFeedListModel.item.model : null

        Loader {
            id: loader
            width: column.width
            asynchronous: true

            Component.onCompleted: {
                var props = {
                    "downloader": accountManager.item.downloader,
                    "providerName": providerName,
                    "subviewModel": eventFeedListModel.item,
                    "viewVisible": Qt.binding(function() { return Desktop.eventsViewVisible }),
                    "eventsColumnMaxWidth": Math.min(Screen.width, Screen.height)
                }
                setSource(Qt.resolvedUrl("file:///usr/share/lipstick/eventfeed/" + providerName + "-delegate.qml"), props)
            }

            onLoaded: {
                column._reloadHasRemovableNotifications()
            }

            Connections {
                target: Lipstick.compositor.eventsLayer
                onDeactivated: {
                    if (loader.item && loader.item.hasOwnProperty("collapsed")) {
                        loader.item.collapsed = true
                    }
                }
            }

            Connections {
                target: loader.item
                onExpanded: {
                    column.expanded(loader.item, itemPosY)
                }
                onHasRemovableItemsChanged: {
                    column._reloadHasRemovableNotifications()
                }
                onMainContentHeightChanged: {
                    if (loader.item.userRemovable) {
                        if (!column.showingRemovableContent && loader.item.mainContentHeight > 0) {
                            column.showingRemovableContent = true
                        } else if (column.showingRemovableContent && loader.item.mainContentHeight == 0) {
                            column._reloadShowingRemovableContent()
                        }
                    }
                }
            }
        }
    }
}
