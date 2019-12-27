import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import org.nemomobile.notifications 1.0
import Nemo.Configuration 1.0
import MeeGo.QOfono 0.2
import org.nemomobile.dbus 2.0
import org.nemomobile.contacts 1.0
import "dialer"

Item {
    id: root

    property bool isCurrentItem
    property alias flickable: flickable
    property alias headerHeight: header.height

    signal endCallClicked
    signal startCallClicked()
    signal numberClicked(string number)
    signal voiceMailCalled

    // Otherwise clicks can be lost (if it were 0 a pressDelay higher in heirarchy would apply)
    property bool isLandscape: pageStack.currentPage && pageStack.currentPage.isLandscape

    signal reset
    onReset: numberField.text = ""

    DBusInterface {
        id: invokerIface
        service: "org.freedesktop.DBus"
        iface: "org.freedesktop.DBus"
        path: "/org/freedesktop/DBus"
        bus: DBusInterface.SessionBus
    }

    DBusInterface {
        id: lockInterface
        service: "org.nemomobile.devicelock"
        iface: "org.nemomobile.lipstick.devicelock"
        path: "/devicelock"
        bus: DBusInterface.SystemBus

        function checkLockState(serviceOrUrl) {
            lockInterface.typedCall("state", [], function (state) {
                if (state == 0) {
                    if (serviceOrUrl['service']) {
                        invokerIface.typedCall("StartServiceByName", [{type:'s', value:serviceOrUrl['service']}, {type:'u', value:0}]);
                    } else {
                        Qt.openUrlExternally(serviceOrUrl['url'])
                    }
                }
            })
        }
    }

    DBusInterface {
        id: settingsInterface
        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"
    }

    function checkSpecial() {
        if (numberField.text.length > 4
                && numberField.text[0] === "*"
                && numberField.text[1] === "#"
                && numberField.text[numberField.text.length - 1] === "*"
                && numberField.text[numberField.text.length - 2] === "#"
                && numberField.text in __specials) {
            lockInterface.checkLockState(__specials[numberField.text])
            clearNumberFieldTimer.restart()
        }
    }

    function dial(modemPath) {
        telephony.dialNumberOrService(numberField.text, modemPath)
        clearNumberFieldTimer.restart()
    }

    function isSimCode(number) {
        var simCodePrefix = [ "**04*", "**042*", "**05*", "**052*" ]

        for (var c = 0; c < simCodePrefix.length; c++) {
            if (numberField.text.indexOf(simCodePrefix[c]) === 0
                    && numberField.text[numberField.text.length-1] === '#') {
                return true
            }
        }

        return false
    }

    function dialVoiceMail(modemPath) {
        var voiceMail = messageWaiting.createObject(null, { 'modemPath': modemPath ? modemPath : telephony.modemPath })
        if (voiceMail.mailboxNumber().length > 0) {
            telephony.dial(voiceMail.mailboxNumber(), modemPath)
        } else {
            //% "No voicemail number is defined"
            voiceMail.notification.previewBody = qsTrId("voicecall-la-no_voicemail_mailbox")
            voiceMail.notification.publish()
        }
        voiceMail.destroy()
    }

    objectName: "softwareInputPanel"

    width: parent.width
    height: parent.height

    onNumberClicked: {
        numberField.input(number)

        root.checkSpecial()

        if (number !== "#") {
            return
        }

        if (numberField.text === "*#06#") {
            // IMEI handled immediately
            // Build object containing IMEI codes.
            var imeis = {}
            for (var i = 0; i < telephony.imeiCodes.length; ++i) {
                imeis["IMEI"+(i+1)] = telephony.imeiCodes[i]
            }

            //% "IMEI"
            supplementaryServices.showServicePage({
                                                      "title": qsTrId("voicecall-he-imei"),
                                                      "properties": imeis
                                                  })
            clearNumberFieldTimer.restart()
        } else if (numberField.text === "*#07#") {
            // should show regulatory information
            settingsInterface.call("showPage", "system_settings/info/about_device")
            clearNumberFieldTimer.restart()
        } else if (isSimCode(numberField.text)) {
            if (Telephony.promptForVoiceSim) {
                _simSelectorOpen = true
            } else {
                simCodes.processCode(numberField.text)
                clearNumberFieldTimer.restart()
            }
        }
    }
    onStartCallClicked: {
        if (telephony.promptForSim(numberField.text)) {
            _simSelectorOpen = true
        } else {
            dial()
        }
    }
    onVoiceMailCalled: {
        if (numberField.text.length != 0) {
            return
        }

        if (telephony.promptForSim(numberField.text)) {
            _simSelectorOpen = true
        } else {
            dialVoiceMail()
        }
    }

    Timer {
        id: clearNumberFieldTimer
        interval: 1000
        onTriggered: numberField.text = ""
    }

    Label {
        y: Theme.paddingSmall
        visible: telephony.enabledModems.length > 1
        text: telephony.simName != undefined ? telephony.simName : ""
        color: Theme.highlightColor
        anchors.horizontalCenter: parent.horizontalCenter
    }

    SilicaFlickable {
        id: flickable

        property int singlePaneHeight: header.height + numberField.height + extraSpacer.height
                                       + keypad.height + callButton.height
        property bool splitView: isLandscape && singlePaneHeight > parent.height

        PullDownMenu {
            MenuItem {
                //% "Send message"
                text: qsTrId("voicecall-me-send_message")
                enabled: numberField.text.length > 0
                onClicked: messaging.startSMS(numberField.text)
            }

            MenuItem {
                //% "Link to contact"
                text: qsTrId("voicecall-me-link_to_contact")
                enabled: numberField.text.length > 0
                onClicked: main.mainPage.linkToContact(numberField.text)
            }

            MenuItem {
                //% "Save as contact"
                text: qsTrId("voicecall-me-save_as_contact")
                enabled: numberField.text.length > 0
                onClicked: main.mainPage.saveAsContact(numberField.text)
            }
        }

        anchors.fill: parent
        contentHeight: Math.max(column.height, header.height + keypad.height)

        Item {
            id: rightSidePane
            anchors.right: parent.right
            width: parent.width / 2
            y: header.height
            height: parent.height - header.height
        }

        Column {
            id: column

            width: flickable.splitView ? (parent.width / 2) : parent.width

            Item {
                id: header
                width: 1
            }

            Item {
                width: 1
                height: flickable.splitView ? 0 : Math.max(0, root.height - flickable.singlePaneHeight)
            }

            NumberField {
                id: numberField
                active: root.isCurrentItem
                keypad: keypad
                rightMargin: flickable.splitView ? Theme.paddingLarge : Theme.horizontalPageMargin
            }

            Item {
                id: extraSpacer
                width: 1
                height: Theme.paddingLarge
            }

            Item {
                id: keypadPlaceholder

                width: parent.width
                height: flickable.splitView ? Theme.paddingLarge : keypad.height

                Keypad {
                    id: keypad

                    property bool dtmfPlaying: dtmfTimer.running || buttonDown
                    property bool buttonDown
                    property int dtmfStep: 0
                    property string lastNumber

                    parent: flickable.splitView ? rightSidePane : keypadPlaceholder
                    preventStealing: false
                    enabled: !_simSelectorOpen

                    onPressed: {
                        keypad.dtmfStep = 0
                        buttonDown = true
                        keypad.lastNumber = number
                        dtmfTimer.restart()
                        main.prepareCallingDialog()
                    }
                    onReleased: buttonDown = false
                    onCanceled: { buttonDown = false; dtmfTimer.stop() }
                    onClicked: root.numberClicked(number)
                    onPressAndHold: {
                        if (number === "*") {
                            numberField.input(",")
                            mouse.accepted = true
                        } else if (number === "0") {
                            numberField.input("+")
                            mouse.accepted = true
                        }
                    }

                    onVoiceMailCalled: root.voiceMailCalled()
                    onDtmfPlayingChanged: {
                        if (!dtmfPlaying) {
                            telephony.stopDtmfTone()
                        }
                    }

                    voiceMailIconSource: numberField.text.length == 0 ? "image://theme/icon-phone-dialer-voicemail" : ""
                    pressedTextColor: telephony.isEmergency ? "red" :  Theme.highlightColor
                    pressedButtonColor: Theme.rgba(telephony.isEmergency ? "#ff1a22" : Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)

                    Binding {
                        target: keypad
                        property: "_buttonHeight"
                        // assuming the default size here and overriding if it doesn't fit
                        when: isLandscape
                              && (Screen.width - root.headerHeight) < 4 * (screen.sizeCategory > Screen.Medium
                                                                           ? Theme.itemSizeExtraLarge : Theme.itemSizeLarge)
                        value: Theme.itemSizeMedium
                    }

                    Timer {
                        id: dtmfTimer
                        interval: 16
                        repeat: true
                        onTriggered: {
                            if (keypad.dtmfStep == 2) { // 48ms before tone starts
                                telephony.stopDtmfTone()
                                telephony.startDtmfTone(keypad.lastNumber)
                            } else if (keypad.dtmfStep == 10) { // tone lasts at least 128ms
                                stop()
                            }
                            ++keypad.dtmfStep
                        }
                    }
                }
            }

            Button {
                id: callButton
                enabled: telephony.effectiveCallCount < 2 && numberField.text.length > 0
                //% "Call"
                text: qsTrId("voicecall-bt-call")
                height: Theme.itemSizeLarge
                objectName: "callButton"
                onClicked: root.startCallClicked()
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    property bool _simSelectorOpen
    on_SimSelectorOpenChanged: if (_simSelectorOpen) simSelectorLoader.createObject(root)

    Component {
        id: simSelectorLoader
        DockedPanel {
            property string selectedModemPath
            dock: Dock.Bottom
            width: parent.width
            height: picker.height
            modal: true
            animationDuration: 200
            open: _simSelectorOpen

            onExpandedChanged: {
                // 'expanded' toggles before animating closed, so we need to trap the second
                // time it changes to false, which is when it is closed and visibleSize is 0
                if (!expanded && visibleSize == 0) {
                    _simSelectorOpen = false
                    destroy()
                }
            }

            SimPicker {
                id: picker
                showBackground: true
                onSimSelected: {
                    selectedModemPath = modemPath
                    if (selectedModemPath.length) {
                        if (numberField.text.length == 0) {
                            // The voicemail button is the only way to initiate a call with an empty numberField
                            dialVoiceMail(selectedModemPath)
                        } else if (isSimCode(numberField.text)) {
                            simCodes.processCode(numberField.text, selectedModemPath)
                        } else {
                            dial(selectedModemPath)
                        }
                    }
                    _simSelectorOpen = false
                }
            }
        }
    }

    Component {
        id: messageWaiting
        Item {
            property alias modemPath: ofonoMessageWaiting.modemPath
            property var notification: Notification {
                urgency: Notification.Critical
                isTransient: true
            }
            function mailboxNumber() {
                if (!simCodes.present(modemPath)) {
                    return ""
                }
                var mailbox = mailboxConfig.value
                if (!ofonoMessageWaiting.error && mailbox == "") {
                    mailbox = ofonoMessageWaiting.voicemailMailboxNumber
                }
                return mailbox
            }
            OfonoMessageWaiting {
                id: ofonoMessageWaiting
                property bool error
                onGetPropertiesFailed: error = true
            }

            ConfigurationValue {
                id: mailboxConfig
                property string simId: simCodes.cardIdentifier(modemPath)
                property string card: simId != "" ? simId : "default"
                key: "/sailfish/voicecall/voice_mailbox/" + card
                defaultValue: ""
            }
        }
    }
}
