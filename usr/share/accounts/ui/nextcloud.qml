/****************************************************************************************
**
** Copyright (C) 2019 Open Mobile Platform LLC
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

OnlineSyncAccountCreationAgent {
    provider: accountProvider
    services: [
        accountManager.service("nextcloud-backup"),
        accountManager.service("nextcloud-caldav"),
        accountManager.service("nextcloud-carddav"),
        accountManager.service("nextcloud-images"),
        accountManager.service("nextcloud-posts"),
        accountManager.service("nextcloud-sharing")
    ]
    webdavPath: "/remote.php/webdav/"
    showAdvancedSettings: true
}
