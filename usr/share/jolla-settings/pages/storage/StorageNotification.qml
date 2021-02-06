/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import Nemo.Notifications 1.0

Notification {
    function notify() {
        publish()
        isTransient = true
        summary = ""
        body = ""
    }

    isTransient: true
    urgency: Notification.Critical
    appIcon: "icon-s-sd-card"
}
