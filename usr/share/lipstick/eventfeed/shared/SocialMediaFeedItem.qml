/****************************************************************************
 **
 ** Copyright (C) 2014 - 2018 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

NotificationGroupMember {
    id: item

    property alias downloader: _avatar.downloader
    property string timestamp: model.timestamp
    property string formattedTime
    property alias avatar: _avatar
    property alias avatarSource: _avatar.source
    property alias fallbackAvatarSource: _avatar.fallbackSource
    property int refreshTimeCount: 1
    property int accountId
    property bool connectedToNetwork

    property real topMargin: Theme.paddingLarge
    property real bottomMargin: Theme.paddingLarge

    property real eventsColumnMaxWidth
    property Item _accountDelegate

    groupHighlighted: _accountDelegate && _accountDelegate.highlighted
    enabled: !housekeeping || !(_accountDelegate && _accountDelegate.hasOnlyOneItem)
    contentLeftMargin: _accountDelegate ? _accountDelegate.contentLeftMargin : Theme.horizontalPageMargin

    lastItem: _accountDelegate && model.index === _accountDelegate.boundedModel.count - 1

    Component.onCompleted: {
        var parentItem = item.parent
        while (parentItem) {
            if (parentItem.hasOwnProperty("__account_delegate")) {
                _accountDelegate = parentItem
                return
            }
            parentItem = parentItem.parent
        }
    }

    onRefreshTimeCountChanged: formattedTime = Format.formatDate(timestamp, Format.DurationElapsed)

    SocialAvatar {
        id: _avatar
        y: topMargin
        accountId: item.accountId
        connectedToNetwork: item.connectedToNetwork
    }
}
