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
import org.nemomobile.systemsettings 1.0

ShareFilePreview {
    id: root

    metadataStripped: true

    //: Describes where mobile uploads will go. %1 is an operating system name
    //% "Mobile uploads from %1"
    remoteDirName: qsTrId("webshare-la-uploads-text").arg(aboutSettings.operatingSystemName)

    AboutSettings {
        id: aboutSettings
    }
}
