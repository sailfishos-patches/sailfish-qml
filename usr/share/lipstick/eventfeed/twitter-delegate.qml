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
import QtQml.Models 2.1
import "shared"

SocialMediaAccountDelegate {
    id: delegateItem

    //: Twitter tweets
    //% "Tweets"
    headerText: qsTrId("lipstick-jolla-home-la-twitter_tweets")
    headerIcon: "image://theme/graphic-service-twitter"
    showRemainingCount: false

    services: ["Posts", "Notifications"]
    socialNetwork: SocialSync.Twitter
    dataType: SocialSync.Posts

    model: TwitterPostsModel {
        onCountChanged: {
            if (count > 0) {
                if (!updateTimer.running) {
                    shortUpdateTimer.start()
                }
            } else {
                shortUpdateTimer.stop()
            }
        }
    }

    delegate: TwitterFeedItem {
        downloader: delegateItem.downloader
        imageList: model.images
        avatarSource: delegateItem.convertUrl(model.icon)
        fallbackAvatarSource: model.icon
        accountId: model.accounts[0]

        onTriggered: {
            Qt.openUrlExternally("https://mobile.twitter.com/" + model.screenName + "/status/" + model.twitterId)
        }

        Component.onCompleted: {
            refreshTimeCount = Qt.binding(function() { return delegateItem.refreshTimeCount })
            connectedToNetwork = Qt.binding(function() { return delegateItem.connectedToNetwork })
            eventsColumnMaxWidth = Qt.binding(function() { return delegateItem.eventsColumnMaxWidth })
        }
    }
    //% "Show more in Twitter"
    expandedLabel: qsTrId("lipstick-jolla-home-la-show-more-in-twitter")

    onHeaderClicked: Qt.openUrlExternally("https://m.twitter.com/")
    onExpandedClicked: Qt.openUrlExternally("https://m.twitter.com/")

    onViewVisibleChanged: {
        if (viewVisible) {
            delegateItem.resetHasSyncableAccounts()
            delegateItem.model.refresh()
            if (delegateItem.hasSyncableAccounts && !updateTimer.running) {
                shortUpdateTimer.start()
            }
        } else {
            shortUpdateTimer.stop()
        }
    }

    onConnectedToNetworkChanged: {
        if (viewVisible) {
            if (!updateTimer.running) {
                shortUpdateTimer.start()
            }
        }
    }

    // The Twitter feed is updated 3 seconds after the feed view becomes visible,
    // unless it has been updated during last 60 seconds. After that it will be updated
    // periodically in every 60 seconds as long as the feed view is visible.

    Timer {
        id: shortUpdateTimer
        interval: 3000
        onTriggered: {
            delegateItem.sync()
            updateTimer.start()
        }
    }

    Timer {
        id: updateTimer
        interval: 60000
        repeat: true
        onTriggered: {
            if (delegateItem.viewVisible) {
                delegateItem.sync()
            } else {
                stop()
            }
        }
    }

    function convertUrl(source) {
        if (source.indexOf("_normal.") !== -1) {
                return source.replace("_normal.", "_bigger.");
        } else if (source.indexOf("_mini.") !== -1) {
            return source.replace("_mini.", "_bigger.");
        }
        return source
    }
}
