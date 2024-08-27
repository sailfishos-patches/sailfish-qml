/*
 * Copyright (c) 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0

AccountCreationManager {
    id: genericAccountCreator

    property bool creationDone

    signal creationCompleted

    Component.onCompleted: {
        if (genericAccountCreator.hasOwnProperty("serviceFilter")) {
            serviceFilter = ["e-mail"]
        }
        startAccountCreation()
    }

    Connections {
        target: endDestination
        onStatusChanged: {
            if (endDestination.status == PageStatus.Active && !creationDone) {
                // don't emit immediately as new pages cannot be pushed at this point
                delayCompletedSignal.start()
            }
        }
    }

    Timer {
        id: delayCompletedSignal
        interval: 1
        onTriggered: {
            creationDone = true
            creationCompleted()
        }
    }
}
