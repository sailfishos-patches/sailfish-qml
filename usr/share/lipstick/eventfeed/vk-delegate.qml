/****************************************************************************
 **
 ** Copyright (C) 2014 - 2015 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.social 1.0
import org.nemomobile.socialcache 1.0
import "shared"

SocialMediaAccountDelegate {
    id: delegateItem

    //: VK News
    //% "News"
    headerText: qsTrId("lipstick-jolla-home-la-vk_posts")
    headerIcon: "image://theme/graphic-service-vk"

    services: ["Posts", "Notifications"]
    socialNetwork: SocialSync.VK
    dataType: SocialSync.Notifications

    model: VKPostsModel {}

    delegate: VKFeedItem {
        downloader: delegateItem.downloader
        imageList: model.images
        accountId: model.accounts[0]
        userRemovable: true
        animateRemoval: defaultAnimateRemoval || delegateItem.removeAllInProgress

        onRemoveRequested: {
            delegateItem.model.remove(model.vkId)
        }

        onTriggered: {
            Qt.openUrlExternally(model.link)
        }

        Component.onCompleted: {
            refreshTimeCount = Qt.binding(function() { return delegateItem.refreshTimeCount })
            connectedToNetwork = Qt.binding(function() { return delegateItem.connectedToNetwork })
            eventsColumnMaxWidth = Qt.binding(function() { return delegateItem.eventsColumnMaxWidth })
        }
    }

    //% "Show more in VK"
    expandedLabel: qsTrId("lipstick-jolla-home-la-show-more-in-vk")
    userRemovable: true

    onHeaderClicked: Qt.openUrlExternally("https://m.vk.com/feed")
    onExpandedClicked: Qt.openUrlExternally("https://m.vk.com/feed")

    onViewVisibleChanged: {
        if (viewVisible) {
            delegateItem.resetHasSyncableAccounts()
            delegateItem.model.refresh()
        }
    }
}
