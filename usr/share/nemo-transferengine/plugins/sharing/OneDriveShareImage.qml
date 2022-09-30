/****************************************************************************************
**
** Copyright (c) 2019 Jolla Ltd.
** Copyright (c) 2019 - 2021 Open Mobile Platform LLC
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

    imageScaleVisible: false
    descriptionVisible: false
    metaDataSwitchVisible: false

    //: Target folder in OneDrive. OneDrive has a special folder called Camera Roll
    //: where images are upload. Localization should match that.
    //% "Camera Roll"
    remoteDirName: qsTrId("webshare-la-onedrive-uploads-videos")
}
