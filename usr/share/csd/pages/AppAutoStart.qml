/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

DBusInterface {
    bus: DBus.SessionBus
    service: "org.freedesktop.systemd1"
    iface: "org.freedesktop.systemd1.Manager"
    path: "/org/freedesktop/systemd1"

    function enableAutostart(callback, failureCallback) {
        typedCall("EnableUnitFiles",
                  [
                      { "type": "as", "value": ["jolla-csd@continueRebootTest.service"] },
                      { "type": "b", "value": false },
                      { "type": "b", "value": false }
                  ],
                  callback,
                  failureCallback)
    }

    function disableAutostart(callback, failureCallback) {
        typedCall("DisableUnitFiles",
                  [
                      { "type": "as", "value": ["jolla-csd@continueRebootTest.service"] },
                      { "type": "b", "value": false }
                  ],
                  callback,
                  failureCallback)
    }
}
