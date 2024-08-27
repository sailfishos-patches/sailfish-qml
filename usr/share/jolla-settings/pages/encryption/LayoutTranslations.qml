/*
 * Copyright (c) 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0

Item {
    // providing dummy translations that can be used on settings layout files
    function qsTrIdString() {
        //% "Do you want to encrypt user data?"
        QT_TRID_NOOP("settings_encryption-la-encrypt_user_data_confirmation")

        // Restoration UI translations
        //% "OK"
        QT_TRID_NOOP("settings_encryption-la-ok")
        //% "Restoring user data"
        QT_TRID_NOOP("settings_encryption-la-restoring-data")
        //% "Restoring user data failed"
        QT_TRID_NOOP("settings_encryption-la-restore-fail-summary")
        //% "Data is kept on memory card"
        QT_TRID_NOOP("settings_encryption-la-restore-fail-body")
    }
}
