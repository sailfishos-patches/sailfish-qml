import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import com.jolla.voicecall.settings.translations 1.0
import QOfono 0.2

Page {
    id: root
    property string modemPath

    backNavigation: ofonoCallForwarding.updateField == -1

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingSmall

            PageHeader {
                //% "Call forwarding"
                title: qsTrId("settings_voicecall-he-call_forwarding")
            }

            Column {
                width: parent.width
                spacing: Theme.paddingSmall
                opacity: busyIndicator.running ? 0.0 : 1.0
                Behavior on opacity { FadeAnimator {}}
                SwitchField {
                    id: allField
                    enabled: !ofonoCallForwarding.networkBusy
                    busy: changed && ofonoCallForwarding.networkBusy
                    systemNumber: ofonoCallForwarding.voiceUnconditional
                    //% "All voice calls"
                    label: qsTrId("settings_voicecall-la-all_voicecalls")
                    showAccept: changed && !ofonoCallForwarding.networkBusy && activeFocus && Qt.inputMethod.visible
                    onEnterClicked: ofonoCallForwarding.updateNetwork(true)
                }

                SwitchField {
                    id: busyField
                    enabled: !ofonoCallForwarding.networkBusy
                    busy: changed && ofonoCallForwarding.networkBusy
                    systemNumber: ofonoCallForwarding.voiceBusy
                    //% "If busy"
                    label: qsTrId("settings_voicecall-la-busy")
                    showAccept: changed && !ofonoCallForwarding.networkBusy && activeFocus && Qt.inputMethod.visible
                    onEnterClicked: ofonoCallForwarding.updateNetwork(true)
                }

                SwitchField {
                    id: noReplyField
                    enabled: !ofonoCallForwarding.networkBusy
                    busy: changed && ofonoCallForwarding.networkBusy
                    systemNumber: ofonoCallForwarding.voiceNoReply
                    //% "If not answered"
                    label: qsTrId("settings_voicecall-la-not_answered")
                    showAccept: changed && !ofonoCallForwarding.networkBusy && activeFocus && Qt.inputMethod.visible
                    onEnterClicked: ofonoCallForwarding.updateNetwork(true)
                }

                SwitchField {
                    id: notReachableField
                    enabled: !ofonoCallForwarding.networkBusy
                    busy: changed && ofonoCallForwarding.networkBusy
                    systemNumber: ofonoCallForwarding.voiceNotReachable
                    //% "If out of reach"
                    label: qsTrId("settings_voicecall-la-out_of_reach")
                    onEnterClicked: ofonoCallForwarding.updateNetwork(true)
                    property bool anyChanged: allField.changed || busyField.changed || noReplyField.changed || notReachableField.changed
                    showAccept: anyChanged && !ofonoCallForwarding.networkBusy
                }
            }
        }
    }

    BusyLabel {
        id: busyIndicator
        running: !ofonoCallForwarding.ready && !ofonoCallForwarding.failed
        //% "Retrieving settings"
        text: qsTrId("settings_voicecall-la-retrieving_settings")
    }

    OfonoCallForwarding {
        id: ofonoCallForwarding
        modemPath: root.modemPath

        property int updateField: -1
        property bool networkBusy: updateField >= 0 || !ready
        function updateNetwork(initiate) {
            if (initiate) {
                updateField = 0
            } else if (updateField < 0) {
                return
            }

            switch (updateField) {
            case 0:
                updateField++
                if (allField.changed) {
                    allField.error = false
                    ofonoCallForwarding.voiceUnconditional = allField.result()
                    break
                }
                // fall through
            case 1:
                updateField++
                if (busyField.changed) {
                    busyField.error = false
                    ofonoCallForwarding.voiceBusy = busyField.result()
                    break
                }
                // fall through
            case 2:
                updateField++
                if (noReplyField.changed) {
                    noReplyField.error = false
                    ofonoCallForwarding.voiceNoReply = noReplyField.result()
                    break
                }
                // fall through
            case 3:
                updateField++
                if (notReachableField.changed) {
                    notReachableField.error = false
                    ofonoCallForwarding.voiceNotReachable = notReachableField.result()
                    break
                }
                // fall through
            default:
                // removes focus from the fields
                updateField = -1
                break
            }
        }

        onVoiceUnconditionalComplete: {
            if (!success) {
                allField.reset()
                allField.error = true
            }
            updateNetwork()
        }
        onVoiceBusyComplete: {
            if (!success) {
                busyField.reset()
                busyField.error = true
            }
            updateNetwork()
        }
        onVoiceNoReplyComplete: {
            if (!success) {
                noReplyField.reset()
                noReplyField.error = true
            }
            updateNetwork()
        }
        onVoiceNotReachableComplete: {
            if (!success) {
                notReachableField.reset()
                notReachableField.error = true
            }
            updateNetwork()
        }
    }
}
