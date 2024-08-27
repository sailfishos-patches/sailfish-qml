/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import QtQuick.Window 2.1 as QtQuickWindow
import QtQml 2.2
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Policy 1.0
import Sailfish.Contacts 1.0
import Nemo.DBus 2.0
import org.nemomobile.contacts 1.0
import Nemo.Notifications 1.0
import org.nemomobile.voicecall 1.0 as VoiceCall
import com.jolla.voicecall 1.0
import "common/CallHistory.js" as CallHistory

import "pages/dialer"
import "calling"
import "common"
import "pages"
import "ota"

ApplicationWindow {
    id: main

    cover: Qt.resolvedUrl("cover/PhoneCover.qml")
    allowedOrientations: Screen.sizeCategory > Screen.Medium
                         ? defaultAllowedOrientations
                         : defaultAllowedOrientations & Orientation.PortraitMask
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText
    _persistentOpenGLContext: true
    _persistentSceneGraph: true
    _coverIsPrimaryWindow: true
    _coverVisible: (main.callingView && main.callingView.activated) ? true : undefined
    _proxyWindow: (main.callingView && main.callingView.activated) ? main.callingView : null

    // states 'null', 'active', 'held', 'dialing', 'alerting', 'incoming', 'waiting', 'disconnected', 'silenced'
    state: 'null'

    property var mainPageComponent
    property var mainPageIncubator
    property bool expediteMainPage

    property Item mainPage
    property QtObject commCallModel
    property QtObject callingView
    property var callPromptDialog
    property var cellularErrorDialog
    property bool mainUIActive: __window.active
    property bool completed
    readonly property date today: Qt.application.active, new Date()

    property bool displayCallView
    property bool haveSilencedCall: telephony.silencedCall != null
    property bool addCallMode
    property bool callViewClosed
    property alias displayDisconnected: _hangupAnimation.running
    property alias hangupAnimation: _hangupAnimation
    property alias callActive: telephony.active

    // Placeholder error texts for translation. We will be using singular
    // format for both multisim and single sim. When text clicked,
    // the setting page will be opened. Disabling sim is not in practice
    // possible with single sim device.

    //: Indicates a SIM is disabled
    //% "SIM is disabled"
    property string simDisabled: qsTrId("voicecall-la-sim_disabled")

    //: Indicates a SIM is not active
    //% "SIM is currently inactive"
    property string simNotActive: qsTrId("voicecall-la-sim_not_active")

    //: Indicates a SIM has not been inserted into the SIM slot
    //% "No SIM card inserted"
    property string simNotInserted: qsTrId("voicecall-la-no_sim_inserted")

    signal mainPageLoaded

    onAddCallModeChanged: updateVisibility()
    onHaveSilencedCallChanged: updateVisibility()

    function qsTrIdStrings() {
        //% "Private number"
        QT_TRID_NOOP("voicecall-la-private_number")
        //% "Conference call"
        QT_TRID_NOOP("voicecall-la-conference_call")
    }

    function reset() {
        if (mainPage) {
            mainPage.reset()
            mainPage.switchToCallHistory()
            if (pageStack.currentPage != mainPage) {
                pageStack.pop(mainPage, PageStackAction.Immediate)
            }
        }
    }

    function showMainPage() {
        reset()
        activate()
    }

    function resetMainPage() {
        if (mainPage) {
            mainPage.reset()
        }
    }

    function resetAndHangup() {
        reset()
        telephony.hangUpAll()
    }

    function updateVisibility() {
        if (!completed) {
            return
        }

        if (main.state !== "active" && main.state !== "held") {
            addCallMode = false
        }
        var mainDisconnected = telephony.effectiveCallCount <= 1 && main.state === 'disconnected'
        if (addCallMode) {
            ensureMainPage(function() { main.activate() })
            hideCallView()
        } else if ((displayCallView || !main.callViewClosed)
                   && (mainDisconnected || (displayCallView && main.state === 'null'))) {
            if (displayCallView) {
                hideCallView()
            }
            if (callEndedDialogLoader.showWhenCallEnds) {
                // Update call details if needed (e.g. if multi-party)
                var callDetails = telephony.primaryCall || telephony.incomingCall
                if (callDetails) {
                    callEndedDialogLoader.prepareWindow(callDetails)
                }
                if (callEndedDialogLoader.callInstance) {
                    callEndedDialogLoader.showWindow()
                }
            } else {
                telephony.error = qsTrId("voicecall-la-remote-hangup")
                var text = "%1 %2".arg(CallHistory.durationText(telephony.callDuration)).arg(telephony.error)
                notification.publishError(text, "image://theme/icon-system-end-call")
            }
        } else if ((telephony.primaryCall && !main.callViewClosed) || telephony.incomingCall) {
            telephony.dtmfToneHistory = ""
            if (main.state === 'incoming'
                    || main.state === 'dialing'
                    || (main.state === 'active' && !callingDialogLoader.active)) {
                showCallView()
                callEndedDialogLoader.prepareWindow(telephony.primaryCall || telephony.incomingCall)
            }
            if (main.state === 'active') {
                // Call connected - move to the top of the call list to show the latest call
                resetMainPage()
            }
        } else if (main.callViewClosed && callingView) {
             callingView.deactivate()
        }
    }

    function showCallView() {
        callEndedDialogLoader.hideWindow()
        main.callViewClosed = false
        main.displayCallView = true
        callingDialog().activate()
        hangupAnimation.stop()
    }

    function hideCallView() {
        main.displayCallView = false
        hangupAnimation.stop()
        if (callingView) {
            callingView.deactivate()
        }
    }

    Loader {
        id: callingDialogLoader
        active: false
        asynchronous: true
        source: "calling/CallDialog.qml"
        onLoaded: {
            callingView = item
            callingView.closing.connect(function(closeEvent) {
                if (main.state === 'incoming') {
                    telephony.silenceIncomingCall()
                } else {
                    main.callViewClosed = true
                    main.displayCallView = false
                    telephony.hangUpAll()
                }
            })
        }
    }

    function prepareCallingDialog() {
        callingDialogLoader.active = true
    }

    function callingDialog() {
        if (!callingView) {
            callingDialogLoader.asynchronous = false
            callingDialogLoader.active = true
        }

        return callingView
    }

    function showCallPrompt(number) {
        if (!callPromptDialog) {
            var callPromptComponent = Qt.createComponent("calling/CallPromptDialog.qml")
            if (callPromptComponent.status === Component.Ready) {
                callPromptDialog = callPromptComponent.createObject(main)
            } else {
                console.log(callPromptComponent.errorString())
                return
            }
        }

        // Normalize embedded whitespace to single space
        number = number.replace(/\s+/g, ' ')
        // Only digits, '+', dtmf pause characters ('p', 'w', ',', and ';') and space are allowed
        number = number.replace(/[^+ 0-9pw,;]/g, '')
        // Remove leading and trailing whitespace
        number = number.replace(/^\s+/, '').replace(/\s+$/, '')
        callPromptDialog.number = number

        callPromptDialog.raise()
        callPromptDialog.show()
    }

    function showCellularErrorDialog() {
        if (!cellularErrorDialog) {
            var cellularErrorComponent = Qt.createComponent("calling/CellularErrorDialog.qml")
            if (cellularErrorComponent.status === Component.Ready) {
                cellularErrorDialog = cellularErrorComponent.createObject(main)
            } else {
                console.log(cellularErrorComponent.errorString())
                return
            }
        }
        cellularErrorDialog.raise()
        cellularErrorDialog.show()
    }

    function setAudioRecording(recording) {
        if (!VoiceCall.VoiceCallAudioRecorder.available) {
            console.log('VoiceCall recording not supported on this device.')
            return
        }

        if (!AccessPolicy.microphoneEnabled && recording) {
            console.log("VoiceCall cannot be recorded because microphone is disabled.")
            return
        }

        if (recording) {
            var name
            var uid
            var incoming = false
            var callerDetails = telephony.incomingCallerDetails || telephony.primaryCallerDetails
            if (callerDetails) {
                if (callerDetails.remoteUid) {
                    uid = Person.normalizePhoneNumber(callerDetails.remoteUid)
                    if (!uid) {
                        uid = callerDetails.remoteUid
                    }
                }
                if (callerDetails.person) {
                    name = callerDetails.person.displayLabel
                }
                if (callerDetails.remoteUid == telephony.lastIncomingLineId) {
                    incoming = true
                }
            } else {
                console.warn('No caller details for recording!')
            }
            VoiceCall.VoiceCallAudioRecorder.startRecording(name || 'unknown', uid || 'unknown', incoming)
        } else {
            VoiceCall.VoiceCallAudioRecorder.stopRecording()
        }
    }

    function getNumberDetail(person, remoteUid) {
        var label = ""
        if (person) {
            var numbers = Person.removeDuplicatePhoneNumbers(person.phoneDetails)
            var minimizedRemoteUid = Person.minimizePhoneNumber(remoteUid)
            for (var i = 0; i < numbers.length; i++) {
                var number = numbers[i].normalizedNumber

                if (Person.minimizePhoneNumber(number) === minimizedRemoteUid) {
                    var detail = numbers[i]
                    label = ContactsUtil.getNameForDetailSubType(detail.type, detail.subTypes, detail.label)
                    break
                }
            }
        }
        return label
    }

    onCallActiveChanged: {
        if (!callActive) {
            VoiceCall.VoiceCallAudioRecorder.stopRecording()
        }
    }

    SequentialAnimation {
        id: _hangupAnimation
        PauseAnimation { duration: 5000 }
        ScriptAction { script: { hideCallView() } }
    }

    Connections {
        target: __window
        onClosing: main.resetAndHangup()
        onActiveChanged: {
            if (__window.active) {
                if (displayCallView && !displayDisconnected) {
                    callingDialog().activate()
                }
            }
        }
    }

    Connections {
        target: Qt.application
        onAboutToQuit: main.resetAndHangup()
    }

    PeopleModel {
        id: people
        filterType: PeopleModel.FilterAll
    }

    MessagesInterface { id: messaging }

    AppVoiceCallManager {
        id: telephony

        onUnrecoverableCallError: showCellularErrorDialog()
    }

    Image {
        // used to determine the icon width to align number field,
        // cover labels and call log page list items properly

        id: callDirectionIcon
        visible: false
        source: "image://theme/icon-s-missed-call"
        width: implicitWidth + dummyMissedLabel.width
        Label {
            id: dummyMissedLabel
            text: "9"
            font { pixelSize: Theme.fontSizeTiny; weight: Font.Bold }
        }
    }

    function _getService(instantiator, modemPath) {
        var service = null
        for (var i = 0; i < instantiator.count; ++i) {
            var obj = instantiator.objectAt(i)
            if (modemPath && obj.modemPath === modemPath) {
                // found specified modem
                return obj
            } else if (obj.modemPath === telephony.modemPath) {
                // fall back to current modem
                service = obj
            }
        }

        if (!service) {
            console.warn("Service not found for modem", modemPath, telephony.modemPath)
        }
        return service
    }

    Instantiator {
        model: telephony.modems
        delegate: CellBroadcast {
            modemPath: modelData
        }
    }

    Instantiator {
        id: supplementaryServices

        function initiateService(command, modemPath) {
            var service = _getService(supplementaryServices, modemPath)
            if (service) {
                service.initiateService(command)
            }
        }
        function showServicePage(properties, modemPath)  {
            var service = _getService(supplementaryServices, modemPath)
            if (service) {
                service.showServicePage(properties)
            }
        }

        model: telephony.modems
        delegate: SupplementaryServices {
            modemPath: modelData
        }
    }

    Instantiator {
        id: simCodes

        function processCode(code, modemPath) {
            var service = _getService(simCodes, modemPath)
            if (service) {
                service.processCode(code)
            }
        }

        function cardIdentifier(modemPath) {
            var service = _getService(simCodes, modemPath)
            return service ? service.cardIdentifier : ""
        }

        function present(modemPath) {
            var service = _getService(simCodes, modemPath)
            return service ? service.present : ""
        }

        model: telephony.modems
        delegate: SimCodes {
            modemPath: modelData
        }
    }

    OtaNotification {}
    Notification {
        id: notification

        function publishError(error, iconUrl) {
            appIcon = iconUrl || ""
            body = error
            publish()
        }

        appIcon: "icon-launcher-phone"
        urgency: Notification.Critical
        isTransient: true
    }

    Connections {
        target: VoiceCall.VoiceCallAudioRecorder

        onCallRecorded: {
            var n = recordingNotification.createObject()

            //% "Call recorded"
            n.summary = qsTrId("voicecall-la-call_recorded")
            n.body = label

            n.publish()
        }

        onRecordingError: {
            var n = recordingNotification.createObject()

            if (error == VoiceCall.VoiceCallAudioRecorder.FileCreation ||
                error == VoiceCall.VoiceCallAudioRecorder.AudioRouting) {
                //% "Could not begin recording"
                n.summary = qsTrId("voicecall-la-could_not_record")
            } else if (error == VoiceCall.VoiceCallAudioRecorder.FileStorage) {
                //% "Could not save recording"
                n.summary = qsTrId("voicecall-la-could_not_save")
            }
            n.remoteActions = []
            n.publish()
        }
    }

    Component {
        id: recordingNotification

        Notification {
            //% "Call recordings"
            appName: qsTrId("voicecall-la-call_recordings")
            category: "x-jolla.voicecall.callrecordings"
            remoteActions: [ {
                "name": "default",
                "service": "com.jolla.settings",
                "path": "/com/jolla/settings/ui",
                "iface": "com.jolla.settings.ui",
                "method": "showCallRecordings"
            }, {
                "name": "app",
                "service": "com.jolla.settings",
                "path": "/com/jolla/settings/ui",
                "iface": "com.jolla.settings.ui",
                "method": "showCallRecordings"
            } ]
        }
    }

    DBusAdaptor {
        service: "com.nokia.telephony.callhistory"
        path: "/org/maemo/m"
        iface: "com.nokia.MApplicationIf"
        xml: "  <interface name=\"com.nokia.telephony.callhistory\">\n\
    <method name=\"launch\">\n\
      <arg name=\"arg\" type=\"as\" direction=\"in\"/>\n\
    </method>\n\
  </interface>\n"

        function launch(arg) {
            ensureMainPage(function() { main.showMainPage() })
        }
    }

    Component {
        id: voicecallAdaptor
        VoicecallUiAdaptor {

            onShow: {
                ensureMainPage(function() { main.activate() })
            }
            onShowOngoing: {
                if (main.state == 'null' || main.state == 'disconnected') {
                    return
                }

                main.addCallMode = false
                updateVisibility()
                showCallView()
            }
            onOpenUrl: {
                if (arg[0] == undefined) {
                    return false
                }
                var number = ""
                var url = decodeURI(arg[0])
                if (url.indexOf("tel://") === 0) {
                    number = url.substr(6)
                } else if (url.indexOf("tel:") === 0) {
                    number = url.substr(4)
                }
                if (number != "") {
                    number = decodeURIComponent(number)
                    showCallPrompt(number)
                }
                return number != ""
            }
            onDial: {
                main.dialNumberOrService(number)
            }
            onDialViaModem: {
                telephony.dialNumberOrService(number, modemPath)
            }
            onShowCellularErrorDialog: {
                main.showCellularErrorDialog()
            }
            onOpenContactCard: {
                var person = people.personByPhoneNumber(number)
                var personObject = !!person ? person : ContactCreator.createContact({"phoneNumbers": [number]})
                pageStack.push(
                            "Sailfish.Contacts.ContactCardPage",
                            { "contact": personObject, "activeDetail": number },
                            PageStackAction.Immediate)
                main.activate()
            }
            onToggleCall: {
                if (main.state === 'incoming' || main.state === 'silenced') {
                    telephony.incomingCall.answer()
                } else if (telephony.primaryCall) {
                    telephony.primaryCall.hangup()
                }
            }
        }
    }

    function dialNumberOrService(number) {
        if (telephony.promptForSim(number)) {
            // In an ideal world all uses of dial() without providing a sim will be
            // replaced with in-place sim selectors. This is here in case anyone hasn't
            // yet switched to their own sim selector.
            var simSelectorComponent = Qt.createComponent(Qt.resolvedUrl("calling/SimSelectPrompt.qml"))
            if (simSelectorComponent.status == Component.Error) {
                console.warn(simSelectorComponent.errorString())
                return
            }

            var simSelector = simSelectorComponent.createObject(main, { "number": number })
            simSelector.show()
        } else {
            telephony.dialNumberOrService(number)
        }
    }

    function ensureMainPage(callback) {
        if (!initialPage) {
            expediteMainPage = true
            mainPageLoaded.connect(callback)
            loadMainPage()
            if (mainPageIncubator) {
                mainPageIncubator.forceCompletion()
            }
        } else {
            callback()
        }
    }

    function loadMainPage() {
        if (mainPageComponent) {
            return
        }
        mainPageDelayTimer.stop()
        expediteMainPage = !__prestart
        mainPageComponent = Qt.createComponent(Qt.resolvedUrl("pages/MainPage.qml"),
                                              __prestart ? Component.Asynchronous : Component.PreferSynchronous)
        if (mainPageComponent.status == Component.Ready) {
            incubateMainPage()
        } else {
            if (mainPageComponent.status == Component.Error) {
                console.warn("Failed loading MainPage", mainPageComponent.errorString())
            } else {
                mainPageComponent.statusChanged.connect(function() {
                    if (mainPageComponent.status == Component.Ready) {
                        incubateMainPage()
                    } else if (mainPageComponent.status == Component.Error) {
                        console.warn("Failed loading MainPage", mainPageComponent.errorString())
                    }
                })
            }
        }
    }

    function incubateMainPage() {
        mainPageIncubator = mainPageComponent.incubateObject(pageStack)
        if (expediteMainPage) {
            mainPageIncubator.forceCompletion()
        }
        if (mainPageIncubator.status != Component.Ready) {
            mainPageIncubator.onStatusChanged = function(status) {
                if (status == Component.Ready) {
                    initialPage = mainPageIncubator.object
                    mainPageIncubator = null
                    mainPage = pageStack.push(initialPage, {}, PageStackAction.Immediate)
                    mainPageLoaded()
                } else if (status == Component.Error) {
                    console.warn("Failed loading MainPage", mainPageComponent.errorString())
                }
            }
            return
        }
        initialPage = mainPageComponent
        mainPageIncubator = null
        mainPage = pageStack.push(initialPage, {}, PageStackAction.Immediate)
        mainPageLoaded()
    }

    Timer {
        id: mainPageDelayTimer
        interval: 10000
        onTriggered: loadMainPage()
    }

    // Switch back to call history if the app has been minimized for longer than 10 minutes (10*60*1000)
    Timer {
        interval: 600000
        running: !Qt.application.active
        onTriggered: main.reset()
    }

    CallEndedDialogLoader {
        id: callEndedDialogLoader
    }

    Component.onCompleted: {
        completed = true

        loadMainPage()
        voicecallAdaptor.createObject(main)
    }
}
