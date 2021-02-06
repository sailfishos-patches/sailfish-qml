/*
 * Copyright (c) 2018 – 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */
import QtQuick 2.0
import Nemo.Notifications 1.0

Notification {
    property bool alreadyPublished

    function show(errorText) {
        summary = errorText
        if (alreadyPublished) {
            // Make sure new banner is shown, call close() to avoid server treating
            // subsequent publish() calls as updates to the existing notification
            close()
        }

        publish()
        alreadyPublished = true
    }

    isTransient: true
}
