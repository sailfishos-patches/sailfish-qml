/****************************************************************************
**
** Copyright (C) 2014-2015 Jolla Ltd.
** Contact: Antti Seppälä <antti.seppala@jollamobile.com>
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

    contentWidth: width - contentLeftMargin
    deleteIconCenterY: _avatar.y + _avatar.height/2

    onRefreshTimeCountChanged: formattedTime = Format.formatDate(timestamp, Format.DurationElapsed)

    SocialAvatar {
        id: _avatar
        y: topMargin
        width: Theme.itemSizeMedium
        height: Theme.itemSizeMedium
        accountId: item.accountId
        connectedToNetwork: item.connectedToNetwork
    }
}
