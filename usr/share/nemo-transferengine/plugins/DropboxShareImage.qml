/****************************************************************************************
**
** Copyright (c) 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/
import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.TransferEngine 1.0

ShareFilePreviewDialog {
    id: root

    imageScaleVisible: false
    descriptionVisible: false
    metaDataSwitchVisible: false

    remoteDirName: "/Apps/Sailfish OS/Pictures"

    onAccepted: {
        shareItem.start()
    }
}

