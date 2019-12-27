import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.dbus 2.0 as NemoDBus

IncomingCallViewBase {
    id: incomingCallView
    property string menuAction
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

    onMenuActiveChanged: {
        if (menuActive) {
            return
        }

        if (menuAction == "answer") {
            telephony.incomingCall.answer()
        } else if (menuAction == "releaseAndAnswer") {
            telephony.releaseAndAnswer()
        }
        menuAction = ""
    }

    onAnswered: {
        if (callCount > 1) {
            menuAction = "answer"
        } else {
            telephony.incomingCall.answer()
        }
    }

    onEndActiveAndAnswered: {
        if (callCount > 2) {
            // We have one call on hold and another active. End the active call and answer incoming.
            menuAction = "releaseAndAnswer"
        } else {
            // need to wait for the active call to change to held before hanging up
            hangupHeld = true
            menuAction = "answer"
        }
    }

    onMuted: telephony.silenceIncomingCall()

    property var person: null
    property string remoteUid
    property var incomingCallerDetails: telephony.incomingCallerDetails
    onIncomingCallerDetailsChanged: {
        if (incomingCallerDetails) {
            person = incomingCallerDetails.person
            remoteUid = incomingCallerDetails.remoteUid
        }
    }

    active: telephony.incomingCallerDetails ? !telephony.incomingCallerDetails.silenced : false
    onActiveChanged: {
        if (active) {
            // Only update this when we become active since we don't want to see UI changes during hide animation
            callWaiting = (telephony.incomingCall && telephony.primaryCall) ||
                         (telephony.primaryCall && telephony.heldCall && telephony.primaryCall !== telephony.heldCall)
        }
    }

    phoneNumber: remoteUid
    firstText: person ? person.primaryName : ""
    secondText: person ? person.secondaryName : ""
    callCount: telephony.effectiveCallCount
    forwarded: telephony.incomingCall && telephony.incomingCall.isForwarded
    silenced: main.state === "silenced"
}
