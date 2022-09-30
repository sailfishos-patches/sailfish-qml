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
import Sailfish.TransferEngine 1.0
import Sailfish.TransferEngine.Plugins 1.0     // load plugin translations

ShareFilePreview {
    id: root

    metadataStripped: true

    //: Placeholder text for tweet text area
    //% "My tweet"
    descriptionPlaceholderText: qsTrId("twittershare-ph-description")
}
