import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import com.jolla.voicecall.settings.translations 1.0
import MeeGo.QOfono 0.2

Page {
    id: root
    property string modemPath

    property bool _changed: {
                allOutgoingField.changed || outgoingInternationalField.changed ||
                outgoingInternationalExceptHomeField.changed ||
                allIncomingField.changed || incomingInternationalField.changed
    }

    backNavigation: ofonoCallBarring.updateField == -1 && !ofonoCallBarring.disablingAll

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        PullDownMenu {
            busy: ofonoCallBarring.disablingAll
            enabled: !ofonoCallBarring.networkBusy
            MenuItem {
                //% "Change barring password"
                text: qsTrId("settings_voicecall-me-change_barring_password")
                onClicked: pageStack.animatorPush(pinInputComponent, { "action": "change" })
            }
            MenuItem {
                enabled: ofonoCallBarring.voiceOutgoing !== "disabled" || ofonoCallBarring.voiceIncoming !== "disabled"
                //: Disable all call barring
                //% "Disable all"
                text: qsTrId("settings_voicecall-me-barring-disable-all")
                onClicked: {
                    //% "Contact your network service provider if you do not know your password"
                    var message = qsTrId("settings_voicecall-la-contact_provider_password")
                    var obj = pageStack.animatorPush(pinInputComponent, { "message": message })
                    obj.pageCompleted.connect(function(pinPage) {
                        pinPage.pinEntered.connect(function(pin) { ofonoCallBarring.disableAllBarring(pin) })
                    })
                }
            }
        }

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingSmall

            PageHeader {
                //% "Call barring"
                title: qsTrId("settings_voicecall-he-call_barring")
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall
                opacity: busyIndicator.running ? 0.0 : 1.0
                Behavior on opacity { FadeAnimator {}}
                ButtonGroup {
                    width: parent.width
                    Column {
                        width: parent.width
                        spacing: Theme.paddingSmall
                        BarSwitch {
                            id: allOutgoingField
                            enabled: !ofonoCallBarring.networkBusy
                            busy: changed && ofonoCallBarring.updateField == 1
                            systemValue: ofonoCallBarring.voiceOutgoing == "all"
                            //% "All outgoing calls"
                            text: qsTrId("settings_voicecall-la-barr_all_outgoing_calls")
                        }
                        BarSwitch {
                            id: outgoingInternationalField
                            enabled: !ofonoCallBarring.networkBusy
                            busy: changed && ofonoCallBarring.updateField == 1
                            systemValue: ofonoCallBarring.voiceOutgoing == "international"
                            //% "Outgoing international calls"
                            text: qsTrId("settings_voicecall-la-barr_outgoing_international_calls")
                        }
                        BarSwitch {
                            id: outgoingInternationalExceptHomeField
                            enabled: !ofonoCallBarring.networkBusy
                            busy: changed && ofonoCallBarring.updateField == 1
                            systemValue: ofonoCallBarring.voiceOutgoing == "internationalnothome"
                            //% "Outgoing international calls except to home country"
                            text: qsTrId("settings_voicecall-la-barr_outgoing_international_calls_except_to_home")
                        }
                    }
                }
                ButtonGroup {
                    width: parent.width
                    Column {
                        width: parent.width
                        spacing: Theme.paddingSmall
                        BarSwitch {
                            id: allIncomingField
                            enabled: !ofonoCallBarring.networkBusy
                            busy: changed && ofonoCallBarring.updateField == 2
                            systemValue: ofonoCallBarring.voiceIncoming == "always"
                            //% "All incoming calls"
                            text: qsTrId("settings_voicecall-la-barr_all_incoming_calls")
                        }
                        BarSwitch {
                            id: incomingInternationalField
                            enabled: !ofonoCallBarring.networkBusy
                            busy: changed && ofonoCallBarring.updateField == 2
                            systemValue: ofonoCallBarring.voiceIncoming == "whenroaming"
                            //% "Incoming calls when roaming outside home country"
                            text: qsTrId("settings_voicecall-la-barr_incoming_whenroaming_calls")
                        }
                    }
                }

                Label {
                    id: updateMessage
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin*2
                    visible: text.length > 0
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignHCenter
                }

                Button {
                    //% "Accept"
                    text: qsTrId("settings_voicecall-bt-accept_changes")
                    opacity: _changed && !ofonoCallBarring.networkBusy ? 1.0 : 0.0
                    Behavior on opacity { FadeAnimation {} }
                    visible: opacity > 0.0
                    height: Theme.itemSizeLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        //% "Contact your network service provider if you do not know your password"
                        var message = qsTrId("settings_voicecall-la-contact_provider_password")
                        var obj = pageStack.animatorPush(pinInputComponent, { "message": message })
                        obj.pageCompleted.connect(function(pinPage) {
                            pinPage.pinEntered.connect(function(pin) { ofonoCallBarring.updateSettings(pin) })
                        })
                    }
                }
            }
        }
    }

    BusyLabel {
        id: busyIndicator
        //% "Retrieving settings"
        text: qsTrId("settings_voicecall-la-retrieving_settings")
        running: !ofonoCallBarring.ready && !ofonoCallBarring.failed
    }

    OfonoCallBarring {
        id: ofonoCallBarring
        modemPath: root.modemPath
        property bool failed
        property int updateField: -1
        property bool disablingAll
        property bool networkBusy: (updateField >= 0 || !ready || disablingAll) && !failed
        property string password

        function updateSettings(pin) {
            password = pin
            updateMessage.text = ""
            ofonoCallBarring.updateField = 0
            ofonoCallBarring.updateNetwork()
        }

        function updateNetwork() {
            if (updateField < 0) {
                return
            }

            switch (updateField) {
            case 0:
                updateField++
                if (allOutgoingField.changed || outgoingInternationalField.changed || outgoingInternationalExceptHomeField.changed) {
                    if (allOutgoingField.checked) {
                        ofonoCallBarring.setVoiceOutgoing("all", password)
                    } else if (outgoingInternationalField.checked) {
                        ofonoCallBarring.setVoiceOutgoing("international", password)
                    } else if (outgoingInternationalExceptHomeField.checked) {
                        ofonoCallBarring.setVoiceOutgoing("internationalnothome", password)
                    } else {
                        ofonoCallBarring.setVoiceOutgoing("disabled", password)
                    }
                    break
                }
                // fall through
            case 1:
                updateField++
                if (allIncomingField.changed || incomingInternationalField.changed) {
                    if (allIncomingField.checked) {
                        ofonoCallBarring.setVoiceIncoming("always", password)
                    } else if (incomingInternationalField.checked) {
                        ofonoCallBarring.setVoiceIncoming("whenroaming", password)
                    } else {
                        ofonoCallBarring.setVoiceIncoming("disabled", password)
                    }
                    break
                }
                // fall through
            default:
                updateField = -1
                password = ""
                break
            }
        }

        function disableAllBarring(pin) {
            disablingAll = true
            ofonoCallBarring.disableAll(pin)
        }

        function qsTrIdString() {
            //% "Changing the status of call barring failed"
            QT_TRID_NOOP("settings_voicecall-la-barring_update_failed")
        }

        onVoiceIncomingComplete: {
            if (!success) {
                updateMessage.text = qsTrId("settings_voicecall-la-barring_update_failed")
                allIncomingField.reset()
                incomingInternationalField.reset()
            }
            updateNetwork()
        }
        onVoiceOutgoingComplete: {
            if (!success) {
                updateMessage.text = qsTrId("settings_voicecall-la-barring_update_failed")
                allOutgoingField.reset()
                outgoingInternationalField.reset()
                outgoingInternationalExceptHomeField.reset()
            }
            updateNetwork()
        }
        onDisableAllComplete: {
            if (!success) {
                updateMessage.text = qsTrId("settings_voicecall-la-barring_update_failed")
                allIncomingField.reset()
                incomingInternationalField.reset()
                allOutgoingField.reset()
                outgoingInternationalField.reset()
                outgoingInternationalExceptHomeField.reset()
            }
            disablingAll = false
        }

        onGetPropertiesFailed: failed = true

        onChangePasswordComplete: {
            if (!success) {
                //% "Changing the call barring password failed"
                updateMessage.text = qsTrId("settings_voicecall-la-barring_password_change_failed")
            } else {
                //% "Changing the call barring password succeeded"
                updateMessage.text = qsTrId("settings_voicecall-la-barring_password_change_succeeded")
            }
        }
    }

    Component {
        id: pinInputComponent

        Page {
            id: pinInputPage
            property string action
            property alias message: pinInput.warningText
            property string _oldPin

            signal pinEntered(string pin)

            backNavigation: false

            PinInput {
                id: pinInput
                //% "Enter call barring code"
                titleText: qsTrId("settings_voicecall-he-enter_call_barring_code")
                showCancelButton: true
                onPinConfirmed: {
                    if (pinInputPage.action == "change") {
                        if (pinInputPage._oldPin === "") {
                            pinInputPage._oldPin = enteredPin
                            requestAndConfirmNewPin()
                        } else {
                            ofonoCallBarring.changePassword(pinInputPage._oldPin, enteredPin)
                            pinInputPage._oldPin = ""
                            pageStack.pop()
                        }
                    } else {
                        pinInputPage.pinEntered(enteredPin)
                        pageStack.pop()
                    }
                }
                onPinEntryCanceled: {
                    pageStack.pop()
                }
            }
        }
    }
}
