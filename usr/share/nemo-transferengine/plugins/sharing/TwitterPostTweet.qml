/****************************************************************************************
**
** Copyright (c) 2013 - 2021 Jolla Ltd.
** Copyright (c) 2021 Open Mobile Platform LLC
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/
import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.TransferEngine 1.0
import Sailfish.TransferEngine.Plugins 1.0     // load plugin translations

SharePostPreview {
    id: root

    supportsUrlType: false

    //: Post a Twitter status update
    //% "Tweet"
    postButtonText: qsTrId("twittershare-la-tweet_update")
}
