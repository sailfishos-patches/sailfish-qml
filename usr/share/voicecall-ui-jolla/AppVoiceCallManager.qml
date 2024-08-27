/**
 * Copyright (c) 2013 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import QtQml 2.1
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import Sailfish.AccessControl 1.0
import org.nemomobile.voicecall 1.0
import QOfono 0.2
import Nemo.Notifications 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.ofono 1.0
import org.nemomobile.systemsettings 1.0
import Connman 0.2
import Nemo.DBus 2.0
import Nemo.Configuration 1.0
import "common/CallHistory.js" as CallHistory

Item {
    id: root

    function qsTrIdStrings()
    {
        //% "Call ended"
        QT_TRID_NOOP("voicecall-la-remote-hangup")

        //% "Network error"
        QT_TRID_NOOP("voicecall-la-generic-error")

        //% "No network coverage"
        QT_TRID_NOOP("voicecall-la-no-network")

        //% "Invalid phone number"
        QT_TRID_NOOP("voicecall-la-invalid-number")
    }

    readonly property alias enableDebugLog: telephony.isDebugEnabled
    property bool active: telephony.voiceCalls.count !== 0
    property string dtmfToneHistory
    property bool isEmergency: primaryCall && primaryCall.isEmergency
    property string modemPath: Telephony.promptForVoiceSim ? requestedModemPath : (modemManager.defaultVoiceModem || ofonoManager.defaultModem)
    property alias modem: ofonoModem
    property alias modems: ofonoManager.modems
    property alias enabledModems: modemManager.enabledModems
    property alias imeiCodes: modemManager.imeiCodes
    readonly property bool callingPermitted: AccessControl.hasGroup(AccessControl.RealUid, "sailfish-phone")
    readonly property bool messagingPermitted: AccessControl.hasGroup(AccessControl.RealUid, "sailfish-messages")

    // primaryCall is the call we will show in the InCallView.  See updateState() for details
    // of which call is considered the primary call.
    property var primaryCall: null
    property var incomingCall: null
    property var heldCall: null
    property var endingCall: null
    property var silencedCall: null
    property var conferenceCall: null
    property var previousPrimaryCall: null
    property bool preferPrimaryCall
    property var callerDetails: new Object
    property var incomingCallerDetails: incomingCall ? callerDetails[incomingCall.handlerId] : null
    property var primaryCallerDetails: primaryCall && callerDetails[primaryCall.handlerId] ? callerDetails[primaryCall.handlerId] : primaryCallDataCache
    property var silencedCallerDetails: silencedCall ? callerDetails[silencedCall.handlerId] : null
    property alias voiceCalls: telephony.voiceCalls
    property int callDuration: primaryCall ? primaryCall.duration : primaryCallDataCache.callDuration
    property alias activeVoiceCall: telephony.activeVoiceCall
    property alias audioMode: telephony.audioMode
    property alias isMicrophoneMuted: telephony.isMicrophoneMuted
    property string error
    property alias ofonoSimManager: ofonoSimManager
    property alias simManager: simManager
    property string dialAfterHold
    property string dialAfterEndedComplete
    property var splitAfterUnheld: null
    property var activePending: null
    property var executeWhenModemActive
    property bool answerAfterEndedComplete
    property string lastIncomingLineId
    property string lastCaller
    property string lastModem
    property string requestedModemPath: modemManager.defaultVoiceModem || ofonoManager.defaultModem
    property int effectiveCallCount
    property bool callEndedLocally
    property alias restartRecovery: restartRecovery.value
    property alias country: registration.country
    property alias registrationStatus: registration.status

    signal callError
    signal unrecoverableCallError

    function debugLog(msg) {
        if (enableDebugLog) {
            console.log(msg)
        }
    }

    onHeldCallChanged: {
        if (heldCall && dialAfterHold.length) {
            telephony.dial(dialAfterHold)
            dialAfterHold = ""
        } else if (!heldCall && splitAfterUnheld) {
            splitAfterUnheld.split()
            activePending = splitAfterUnheld
            splitAfterUnheld = null
        }
    }

    onEndingCallChanged: {
        if (!endingCall && dialAfterEndedComplete.length) {
            telephony.dial(dialAfterEndedComplete)
            dialAfterEndedComplete = ""
        } else if (!endingCall && answerAfterEndedComplete) {
            if (incomingCall) {
                incomingCall.answer()
            } else if (silencedCall) {
                silencedCall.answer()
            }

            answerAfterEndedComplete = false
        }
    }

    function hangupCall(call) {
        if (!call.isMultiparty) {
            lastCaller = call.lineId
        }
        callEndedLocally = true
        lastModem = modemPath
        call.hangup()
    }

    function hangUpAll() {
        for (var index = 0; index < voiceCalls.count; ++index) {
            voiceCalls.instance(index).hangup()
        }
    }

    function checkError() {
        return telephony.isError()
    }

    function isEmergencyNumber(number) {
        return ofonoVoiceCallManager.emergencyNumbers.indexOf(number) !== -1
    }

    function promptForSim(number) {
        return Telephony.promptForVoiceSim && (number === undefined || !isEmergencyNumber(number))
    }

    // TODO: refactor DTMF handling in some centeralized place, add tests.
    // Provides the sent dtmf tones as a string to in-call UI.
    function updateDtmfToneHistory(number) {
        dtmfToneHistory = dtmfToneHistory + number
    }

    function dial(number, modemPath) {
        telephony.dialedNumber = number
        if (isEmergencyNumber(number)) {
            // Dial emergency number immediately on current modem
            telephony.handleEmergencyCall()
            return
        }
        if (Telephony.promptForVoiceSim) {
            executeWhenModemActive = function() { dialOnCurrentModem(number) }
            requestedModemPath = modemPath
            tryExecuteOnModemActive()
        } else {
            dialOnCurrentModem(number)
        }
    }

    function dialOnCurrentModem(number) {
        lastIncomingLineId = ''
        var normalizedNumber = Person.normalizePhoneNumber(number)
        for (var ic = 0; ic < voiceCalls.count; ic++) {
            var call = voiceCalls.instance(ic)
            if (Person.normalizePhoneNumber(call.lineId) === normalizedNumber) {
                if (call.status !== VoiceCall.STATUS_DISCONNECTED && call.status !== VoiceCall.STATUS_NULL) {
                    var caller = CallHistory.callerNameShort(callerDetails[call.handlerId].person, number)
                    //: Shown when user attemps to call a number that is already being called to
                    //%  "A call to %1 is ongoing"
                    notification.publishError(qsTrId("voicecall-la-call_is_ongoing").arg(caller))
                    return
                }
            }
        }

        dialAfterEndedComplete = ""

        if (!telephony.isError()) {
            if (main.state === "incoming" || main.state === "dialing" || main.state === "silenced") {
                //: If a call is incoming or dialing, you cannot begin a new call
                //% "Cannot call while a call is pending"
                notification.publishError(qsTrId("voicecall-la-cannot-dial-while-active"))
                return
            }

            if (primaryCall && primaryCall.status === VoiceCall.STATUS_ACTIVE && !heldCall) {
                //XXX See https://bz.jollamobile.com/show_bug.cgi?id=11865
                dialAfterHold = normalizedNumber
                primaryCall.hold(true)
            } else if (endingCall) {
                dialAfterEndedComplete = normalizedNumber
            } else {
                telephony.dial(normalizedNumber)
            }
        }
    }

    function dialNumberOrService(number, modemPath) {
        if (isSupplementaryService(number)) {
            supplementaryServices.initiateService(number, modemPath)
        } else {
            dial(number, modemPath)
        }
    }

    // End the active call, then answer
    function releaseAndAnswer() {
        if (incomingCall || silencedCall) {
            if (primaryCall && primaryCall.status === VoiceCall.STATUS_ACTIVE) {
                answerAfterEndedComplete = true
                primaryCall.hangup()
            } else if (incomingCall) {
                incomingCall.answer()
            } else {
                silencedCall.answer()
            }
        }
    }

    function silenceIncomingCall() {
        telephony.silenceRingtone()
        // If call has been already silenced, incomingCallerDetails is null and silencedCallerDetails is valid.
        if (incomingCallerDetails) {
            incomingCallerDetails.silenced = true
            mceDBusRequest.ignoreIncomingCall()
        }
        if (main.hangupAnimation.running) {
            main.hangupAnimation.pause()
        }
    }

    function merge(call1, call2) {
        if (call1.status === VoiceCall.STATUS_ACTIVE && call2.status === VoiceCall.STATUS_HELD) {
            if (conferenceCall) {
                debugLog("HAVE CONFERENCE " + conferenceCall.handlerId + " " + call1.handlerId + " " + call2.handlerId)
                if (call1 === conferenceCall) {
                    debugLog("MERGE CALL2 INTO CALL1")
                    conferenceCall.merge(call2.handlerId)
                } else if (call2 === conferenceCall) {
                    debugLog("MERGE CALL1 INTO CALL2")
                    conferenceCall.merge(call1.handlerId)
                } else {
                    console.warn("Attempted to merge two calls, excluding the active conference")
                }
            } else {
                debugLog("DO NOT HAVE CONFERENCE CALL")
                call1.merge(call2.handlerId)
            }
        } else {
            console.warn("Cannot create a conference call without an active call and held call")
        }
    }

    function split(call) {
        if (!conferenceCall) {
            console.warn("Cannot split call without a conference")
            return
        }
        if (conferenceCall === heldCall) {
            // We can only split if we are active, so first unhold.
            // Once split the conference will be on hold again.
            splitAfterUnheld = call
            conferenceCall.hold(false)
        } else {
            call.split()
        }
    }

    function updateState() {
        telephony.updateState()
    }

    function callsInConference() {
        var calls = []
        for (var ic = 0; ic < telephony.voiceCalls.count; ic++) {
            if (call.parentCall.handlerId == conferenceCall.handlerId) {
                calls.push(call)
            }
        }

        return calls
    }

    function startDtmfTone(tone) {
        telephony.startDtmfTone(tone)
    }

    function stopDtmfTone() {
        telephony.stopDtmfTone()
    }

    function isSupplementaryService(number) {
        return number.length > 3 && (number[0] === '*' || number[0] === '#')
                && number[number.length-1] === '#';
    }

    function simNameForCall(callHandler) {
        // Only report SIM names when there are multiple SIMS
        if (!callHandler || !callHandler.providerId
                || !simManager.valid || simManager.enabledModems.length <= 1) {
            return ""
        }
        var modems = simManager.availableModems
        var lastSlash = callHandler.providerId.lastIndexOf('/')
        if (lastSlash >= 0) {
            var modem = callHandler.providerId.substr(lastSlash)
            for (var i = 0; i < modems.length; i++) {
                if (modem == modems[i]) {
                    return simManager.simNames[i]
                }
            }
        }
        return ""
    }

    VoiceCallManager {
        id: telephony

        property string dialedNumber
        readonly property string ringAccountPath: "/org/freedesktop/Telepathy/Account/ring/tel"

        function isError() {

            var error = false
            var disabledByMdm = simFiltersHelper.ready && !simFiltersHelper.anyActiveSimCanDial
                                && (!main.callHistoryPage || main.callHistoryPage.status == PageStatus.Inactive || !Qt.application.active)
            if (!ofonoSimManager.present || !callingPermitted) {
                //% "Only emergency calls allowed"
                notification.publishError(qsTrId("voicecall-la-only-emergency-allowed"))
                error = true
            } else if (network.flightMode) {
                //% "Not allowed in flight mode"
                notification.publishError(qsTrId("voicecall-la-flight-mode"))
                error = true
            } else if (ofonoSimManager.notActive) {
                pinQuery.call("requestSimPin", [])
                error = true
            } else if (disabledByMdm) {
                //: %1 is an operating system name without the OS suffix
                //% "Outgoing calls are disabled by the %1 Device Manager"
                notification.publishError(qsTrId("voicecall-la-outgoing_disabled_by_mdm")
                                          .arg(aboutSettings.baseOperatingSystemName))
                error = true
            } else if (registration.noNetwork) {
                notification.publishError(qsTrId("voicecall-la-no-network"))
                error = true
            }
            if (error) {
                if (callingPermitted && !disabledByMdm) {
                    main.commCallModel.createOutgoingCallEvent(ringAccountPath + modemPath, dialedNumber)
                }
                root.callError()
            }

            return error
        }

        function updateState() {
            debugLog("Call count: " + voiceCalls.count)
            var newIncomingCall = null
            var newHeldCall = null
            var newEndingCall = null
            var newSilencedCall = null
            var newConferenceCall = null
            var newCallCount = 0
            for (var ic = 0; ic < voiceCalls.count; ic++) {
                var call = voiceCalls.instance(ic)
                if (call.isMultiparty && call.status !== VoiceCall.STATUS_NULL) {
                    newConferenceCall = call
                    break
                }
            }

            for (ic = 0; ic < voiceCalls.count; ic++) {
                call = voiceCalls.instance(ic)
                debugLog("call: " + call.lineId + "  state: " + call.statusText + "   " + call.status + "   " + call.handlerId + "   " + call.parentCall)
                if (!call.parentCall) {
                    if (call.status === VoiceCall.STATUS_ALERTING || call.status === VoiceCall.STATUS_DIALING) {
                        primaryCallDataCache.callDuration = 0
                        main.callViewClosed = false
                    } else if (call.status === VoiceCall.STATUS_INCOMING || call.status === VoiceCall.STATUS_WAITING) {
                        // We treat waiting calls as incoming calls
                        if (!callerDetails.hasOwnProperty(call.handlerId) || !callerDetails[call.handlerId].silenced) {
                            lastCaller = call.lineId
                            lastModem = modemPath
                            newIncomingCall = call
                            var caller = callerDetails[call.handlerId]
                            if (!doNotDisturb.value
                                    || doNotDisturbRingtone.value == "on"
                                    || (doNotDisturbRingtone.value == "contacts" && caller.person && caller.person.id != 0)
                                    || (doNotDisturbRingtone.value == "favorites" && caller.person && caller.person.favorite)) {
                                if (simManager.indexOfModem(modemPath) === 1) {
                                    if (profileControl.ringerTone2Enabled) {
                                        telephony.playRingtone(profileControl.ringerTone2File)
                                    }
                                } else {
                                    telephony.playRingtone()
                                }
                            }
                        } else if (callerDetails[call.handlerId].silenced) {
                            newSilencedCall = call
                        }
                    } else if (call.status === VoiceCall.STATUS_HELD) {
                        newHeldCall = call
                    } else if (call.status === VoiceCall.STATUS_DISCONNECTED) {
                        newEndingCall = call
                        lastCaller = call.lineId
                        lastModem = modemPath
                    } else if (call.status === VoiceCall.STATUS_NULL) {
                        debugLog("Ignoring call with null status")
                    }
                    newCallCount++
                }
            }

            // primaryCall is the call that has the highest priority status as defined below
            var statusPriority = [
                        VoiceCall.STATUS_ALERTING,
                        VoiceCall.STATUS_DIALING,
                        VoiceCall.STATUS_DISCONNECTED,
                        VoiceCall.STATUS_ACTIVE,
                        VoiceCall.STATUS_HELD
                    ]

            var newPrimaryCall = null
            for (var p = 0; p < statusPriority.length; p++) {
                for (var i = 0; i < voiceCalls.count; i++) {
                    var voiceCall = voiceCalls.instance(i)
                    if (voiceCall.status === statusPriority[p] && voiceCall.parentCall === null) {
                        // This is a candidate for the primary call.
                        // Try to maintain the same primary call as last time in case we are in the process of merging calls.
                        if (!newPrimaryCall || voiceCall === primaryCall || (statusPriority[p] === VoiceCall.STATUS_ACTIVE && voiceCall === activePending)) {
                            newPrimaryCall = voiceCall
                        }
                    }
                }
                if (newPrimaryCall) {
                    break
                }
            }

            if (newPrimaryCall !== primaryCall) {
                previousPrimaryCall = primaryCall
            }

            effectiveCallCount = newCallCount
            incomingCall = newIncomingCall
            heldCall = newHeldCall
            endingCall = newEndingCall
            silencedCall = newSilencedCall
            conferenceCall = newConferenceCall
            primaryCall = newPrimaryCall

            var cachedCaller
            if (primaryCall && callerDetails[primaryCall.handlerId]) {
                cachedCaller = primaryCall.handlerId
            } else if (incomingCall && callerDetails[incomingCall.handlerId]) {
                cachedCaller = incomingCall.handlerId
                primaryCallDataCache.callDuration = 0
            } else if (silencedCall && callerDetails[silencedCall.handlerId]) {
                cachedCaller = silencedCall.handlerId
            }

            if (cachedCaller) {
                primaryCallDataCache.avatar = callerDetails[cachedCaller].avatar
                primaryCallDataCache.person = callerDetails[cachedCaller].person
                primaryCallDataCache.startedAt = callerDetails[cachedCaller].startedAt
                primaryCallDataCache.remoteUid = callerDetails[cachedCaller].remoteUid
            }

            if (!incomingCall) {
                answerAfterEndedComplete = false
            } else {
                lastIncomingLineId = incomingCall.lineId
            }

            if (incomingCall) {
                main.state = "incoming"
            } else if (silencedCall && !preferPrimaryCall) {
                main.state = "silenced"
            } else {
                main.state = primaryCall ? primaryCall.statusText : "null"
            }
            preferPrimaryCall = false

            main.updateVisibility()

            if (activePending && primaryCall === activePending) {
                activePending = null
            }

            function lineId(call) { return call.isMultiparty ? "Conference" : call.lineId }

            debugLog("Effective call count: " + effectiveCallCount)
            debugLog("primaryCall:  " + (primaryCall ? lineId(primaryCall) : 'null'))
            debugLog("previousPrimaryCall:  " + (previousPrimaryCall ? lineId(previousPrimaryCall) : 'null'))
            debugLog("heldCall:     " + (heldCall ? lineId(heldCall) : 'null'))
            debugLog("endingCall:   " + (endingCall ? lineId(endingCall) : 'null'))
            debugLog("incomingCall: " + (incomingCall ? incomingCall.lineId : 'null'))
            debugLog("silencedCall: " + (silencedCall ? silencedCall.lineId : 'null'))
            debugLog("main state:   " + main.state)
        }

        function handleEmergencyCall() {

            // To make an emergency call: (as per ofono emergency-call-handling.txt)
            // 1) Set org.ofono.Modem online=true
            // 2) Dial number using telephony VoiceCallManager
            if (!modem.online) {
                modem.onlineChanged.connect(handleEmergencyCall)
                modem.online = true
                return
            }
            modem.onlineChanged.disconnect(handleEmergencyCall)
            telephony.dial(dialedNumber)
        }

        modemPath: root.modemPath

        onModemPathChanged: tryExecuteOnModemActive()

        onVoiceCallsChanged: {
            if (voiceCalls.count == 0) {
                main.callViewClosed = false
            }
        }

        onError: {
            var needsPublish = true
            if (!Qt.application.active && isError()) {
                return
            } else if(message.indexOf("Error.Disconnected") !== -1 && registration.noNetwork) {
                root.error = qsTrId("voicecall-la-no-network")
            } else if (message.indexOf("closed - user") !== -1 || message.indexOf("Release By User") !== -1) {
                // Don't show notification, call ended window has already been shown.
                needsPublish = false
            } else if (message.indexOf("Error.Cancelled") !== -1) {
                // Don't show notification, notification already published in main when the
                // state first changed to disconnected/null.
                needsPublish = false
            } else if (message.indexOf("Error.InvalidHandle") !== -1) {
                root.error = qsTrId("voicecall-la-invalid-number")
            } else {
                root.error = qsTrId("voicecall-la-generic-error")
            }

            if ((!Qt.application.active || !main.displayCallView)
                    && needsPublish) {
                notification.publishError(root.error)
            }

            console.log("VoiceCallManager::onError ", message, "\n")
        }
    }

    Timer {
        id: updateStateTimer
        interval: 60
        onTriggered: telephony.updateState()
    }

    Instantiator {
        id: callMonitor
        model: telephony.voiceCalls
        delegate: QtObject {
            id: details
            property string handlerId: instance.handlerId
            property string remoteUid
            property int callStatus: instance.status
            property var startedAt: instance.startedAt
            property var person: null
            property url avatar: (person !== null && person.avatarPath != "image://theme/icon-m-telephony-contact-avatar") ? person.avatarPath : ""
            property bool silenced
            property string _lineId: isMultiparty ? qsTrId("voicecall-la-conference_call") : lineId
            property bool inConference: parentCall !== null
            on_LineIdChanged: {
                if (_lineId.length > 0) {
                    remoteUid = _lineId
                    person = !isMultiparty && remoteUid !== "" ? people.personByPhoneNumber(remoteUid) : null
                    if (!person) {
                        person = Qt.createQmlObject("import org.nemomobile.contacts 1.0; Person {}", details, "VoiceCallManager.qml")
                        person.phoneDetails = [{ "number": remoteUid, "type": Person.PhoneNumberType, "index": -1 }]
                        person.resolvePhoneNumber(remoteUid, false)
                    }
                }
            }

            onCallStatusChanged: {
                if (callStatus === VoiceCall.STATUS_DISCONNECTED) {
                    telephony.updateState()
                } else if (callStatus === VoiceCall.STATUS_ACTIVE && silenced === true) {
                    // answered a silenced call
                    silenced = false
                    main.hangupAnimation.stop()
                    // updateState() done by onSilencedChanged
                } else {
                    updateStateTimer.restart()
                }
            }
            onSilencedChanged: telephony.updateState()
            onInConferenceChanged: updateStateTimer.restart()
            Component.onCompleted: {
                remoteUid = instance.isMultiparty ? qsTrId("voicecall-la-conference_call") : instance.lineId
                // XXX do we want to delay this a little?
                person = !instance.isMultiParty && remoteUid !== "" ? people.personByPhoneNumber(remoteUid) : null
            }
        }
        onObjectAdded: {
            callerDetails[object.handlerId] = object
            telephony.updateState()
        }
        onObjectRemoved: {
            delete callerDetails[object.handlerId]
            telephony.updateState()
        }
    }

    OfonoManager {
        id: ofonoManager
    }

    OfonoModemManager {
        id: modemManager
        onModemError: if (errorId == "rild-restart" && !restartRecovery.value) unrecoverableCallError()
    }

    OfonoModem {
        id: ofonoModem
        modemPath: root.modemPath
    }

    OfonoSimManager {
        id: ofonoSimManager
        property bool notActive: present && (pinRequired === OfonoSimManager.SimPin || pinRequired === OfonoSimManager.SimPuk)
        onReadyChanged: tryExecuteOnModemActive()
        modemPath: root.modemPath
    }

    OfonoVoiceCallManager {
        id: ofonoVoiceCallManager
        modemPath: root.modemPath
    }

    OfonoNetworkRegistration {
        id: registration
        property bool noNetwork: status != "registered" && status != "roaming" || strength === 0
        modemPath: root.modemPath
        onReadyChanged: tryExecuteOnModemActive()
        onNoNetworkChanged: tryExecuteOnModemActive()
    }

    NetworkManagerFactory {
        id: network
        property bool flightMode: instance.offlineMode
    }

    SimManager {
        id: simManager
        // TODO: Check whether simDescriptionSeparator is really needed, see JB#50515
        simDescriptionSeparator: " " + String.fromCharCode(0x2022) + " "
    }

    ProfileControl {
        id: profileControl
    }

    DBusInterface {
        id: pinQuery
        service: "com.jolla.PinQuery"
        path: "/com/jolla/PinQuery"
        iface: "com.jolla.PinQuery"
        signalsEnabled: true
        function requestCanceled(modemPath) {
            executeWhenModemActive = undefined
        }
    }

    QtObject {
        id: primaryCallDataCache
        property url avatar: ""
        property var person: null
        property var startedAt: new Date()
        property string remoteUid
        property int callDuration
    }

    Connections {
        target: main
        onStateChanged: {
            if (main.state === "incoming" || main.state === "dialing") {
                callEndedLocally = false
            } else if (main.state === "disconnected") {
                root.error = qsTrId("voicecall-la-remote-hangup")
            }
        }
    }

    Connections {
        target: primaryCall
        onDurationChanged: if (primaryCall.duration > 0) primaryCallDataCache.callDuration = primaryCall.duration
    }

    Connections {
        target: main.callingView
        onVisibleChanged: {
            if (!main.callingView.visible) {
                root.error = ""
            }
        }
    }

    function tryExecuteOnModemActive() {
        if (!!executeWhenModemActive && ofonoSimManager.ready) {
            if (ofonoSimManager.notActive) {
                pinQuery.call("requestSimPin", [])
                return
            }

            if (!registration.ready || registration.noNetwork) {
                return
            }

            if (!telephony.isError()) {
                executeWhenModemActive()
            }
            executeWhenModemActive = undefined
        }
    }

    // If we're waiting for a modem to be ready to dial we can't
    // always know why its taking so long. Cancel execution rather than allow a
    // suprise when the modem finally becomes available.
    Timer {
        interval: 10000
        running: !!executeWhenModemActive
        onTriggered: {
            if (!!executeWhenModemActive) {
                if (!ofonoSimManager.notActive) {
                    telephony.isError()
                }
                executeWhenModemActive = undefined
            }
        }
    }

    DBusInterface {
        id: mceDBusRequest
        bus: DBus.SystemBus
        service: 'com.nokia.mce'
        path: '/com/nokia/mce/request'
        iface: 'com.nokia.mce.request'

        function ignoreIncomingCall() {
            call("req_ignore_incoming_call", undefined)
        }
    }

    ConfigurationValue {
        id: restartRecovery
        key: "/sailfish/rild/restart_recovery"
        defaultValue: true
        Component.onCompleted: {
            if (!telephony.restartRecovery) {
                // Clean up any old cellular notifications shown on rild crash/restart
                var notifications = notification.notificationsByCategory("x-jolla.cellular.error")
                for (var i = 0; i < notifications.length; i++) {
                    notifications[i].close()
                }
            }
        }
    }

    ConfigurationValue {
        id: doNotDisturb
        defaultValue: false
        key: "/lipstick/do_not_disturb"
    }

    ConfigurationValue {
        id: doNotDisturbRingtone

        defaultValue: "on"
        key: "/lipstick/do_not_disturb_ringtone"
    }

    AboutSettings {
        id: aboutSettings
    }
}
