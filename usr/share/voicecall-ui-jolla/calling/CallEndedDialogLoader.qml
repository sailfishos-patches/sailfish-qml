/*
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0

Loader {
    id: callEndedDialogLoader

    property var callInstance
    property var callerDetails
    property bool showWhenCallEnds: {
        var allowedToReact = telephony.callingPermitted || telephony.messagingPermitted
        var hasReminder = item && item.reminder.exists
        return allowedToReact && (!telephony.callEndedLocally || hasReminder)
    }

    property bool _showWhenLoaded

    function prepareWindow(call) {
        callInstance = null
        callerDetails = null

        if (!call || !call.handlerId || !call.lineId) {
            console.log("CallEndedDialog prepare() failed, invalid call data!")
            return
        }

        callInstance = call
        callerDetails = telephony.callerDetails[call.handlerId]
        if (item) {
            item.init(callInstance, callerDetails)
        } else {
            active = true
        }
    }

    function showWindow() {
        if (!callInstance) {
            console.log("CallEndedDialog show() failed, prepare() was not called!")
            return
        }

        if (item) {
            item.activate()
        } else {
            _showWhenLoaded = true
            asynchronous = false
            active = true
        }

    }

    function hideWindow() {
        if (status === Loader.Ready) {
            item.dismiss()
        }
    }

    asynchronous: true
    active: false
    source: Qt.resolvedUrl("CallEndedDialog.qml")

    onLoaded: {
        item.init(callInstance, callerDetails)
        if (_showWhenLoaded) {
            item.activate()
        }
        _showWhenLoaded = false
    }
}
