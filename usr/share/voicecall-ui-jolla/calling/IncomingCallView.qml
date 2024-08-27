/*
 * Copyright (c) 2012 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Policy 1.0
import org.nemomobile.contacts 1.0
import Nemo.DBus 2.0 as NemoDBus

IncomingCallViewBase {
    id: incomingCallView
    property bool hangupHeld
    property var heldCall: telephony.heldCall
    onHeldCallChanged:  {
        if (hangupHeld && heldCall) {
            heldCall.hangup()
            hangupHeld = false
        }
    }

    NemoDBus.DBusInterface {
        bus: NemoDBus.DBus.SystemBus
        service: 'com.nokia.mce'
        path: '/com/nokia/mce/signal'
        iface: 'com.nokia.mce.signal'
        signalsEnabled: true

        function call_ui_feedback_ind(event) {
            if (event == "powerkey" || event == "flipover") {
                incomingCallView.muted()
            }
        }
    }

    onAnswered: {
        var call = telephony.incomingCall || telephony.silencedCall
        call.answer()
    }

    onRejected: {
        var call = telephony.incomingCall || telephony.silencedCall
        telephony.hangupCall(call)
        main.hangupAnimation.complete()
    }

    onEndActiveAndAnswered: {
        if (callCount > 2) {
            // We have one call on hold and another active. End the active call and answer incoming.
            telephony.releaseAndAnswer()
        } else {
            // need to wait for the active call to change to held before hanging up
            var call = telephony.incomingCall || telephony.silencedCall
            call.answer()
            hangupHeld = true
        }
    }

    onMuted: telephony.silenceIncomingCall()

    property var person: null
    property string remoteUid
    property var callerDetails: main.state === "silenced" ? telephony.silencedCallerDetails : telephony.incomingCallerDetails
    onCallerDetailsChanged: {
        if (callerDetails) {
            person = callerDetails.person
            remoteUid = callerDetails.remoteUid
        }
    }
    active: main.state === "silenced" || main.state === "incoming"
    onActiveChanged: {
        if (active) {
            // Only update this when we become active since we don't want to see UI changes during hide animation
            callWaiting = (telephony.incomingCall && telephony.primaryCall) ||
                         (telephony.primaryCall && telephony.heldCall && telephony.primaryCall !== telephony.heldCall)
        }
    }

    numberDetail: main.getNumberDetail(person, remoteUid)
    phoneNumber: remoteUid
    firstText: {
        if (person) {
            if (isPortrait) {
                return person.primaryName
            } else {
                return person.primaryName + " " + person.secondaryName
            }
        }
        return ""
    }
    secondText: {
        if (person && isPortrait) {
            return person.secondaryName
        }
        return ""
    }
    callCount: telephony.effectiveCallCount
    forwarded: telephony.incomingCall && telephony.incomingCall.isForwarded
    silenced: main.state === "silenced"
    focus: true

    Keys.onVolumeDownPressed: if (keysResource.acquired) telephony.silenceIncomingCall()
    Keys.onVolumeUpPressed: if (keysResource.acquired) telephony.silenceIncomingCall()

    Permissions {
        autoRelease: true
        applicationClass: "call"
        enabled: main.state === "incoming"

        Resource {
            id: keysResource
            type: Resource.ScaleButton
            optional: true
        }
    }
}
