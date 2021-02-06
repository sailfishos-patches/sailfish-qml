/****************************************************************************
**
** Copyright (c) 2016 - 2019 Jolla Ltd.
** Copyright (c) 2020 Open Mobile Platform LLC.
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0 as Telephony
import Sailfish.Settings.Networking 1.0
import Sailfish.AccessControl 1.0
import com.jolla.settings.system 1.0

Page {
    id: root

    readonly property bool admin: AccessControl.hasGroup(AccessControl.RealUid, "sailfish-system")

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: multiSimColumn.height

        SimActivationPullDownMenu {
            id: pullDownMenu
            showSimActivation: false    // only interested in checking for flight mode
        }

        SimViewPlaceholder {
            id: mainPlaceholder
            simActivationPullDownMenu: pullDownMenu
        }

        Column {
            id: multiSimColumn

            width: parent.width
            enabled: !mainPlaceholder.enabled
            opacity: 1 - mainPlaceholder.opacity

            PageHeader {
                //% "SIM cards"
                title: qsTrId("settings_networking-sim_cards")
            }

            Repeater {
                id: enabledModemRepeater

                model: voiceSimSelector.modemManager.modemSimModel
                delegate: TextSwitch {
                    enabled: admin && voiceSimSelector.valid
                    busy: !voiceSimSelector.valid
                    automaticCheck: false
                    text: longSimDescription
                    description: enabled && errorState.errorState ? errorState.errorString
                                                                  : operatorDescription

                    checked: modemEnabled
                    onClicked: {
                        // JB#43226 Remove once emergency call list can be obtained from disabled SIM
                        if (modemEnabled && voiceSimSelector.modemManager.enabledModems.length === 1) {
                            // If the user only has one active modem, disallow it from being disabled
                            //: Notification that is shown when the user tries to disable the last active SIM card.
                            //% "You must have at least one SIM slot enabled"
                            Notices.show(qsTrId("settings_networking-no-at_least_one_sim"))
                            return
                        }

                        voiceSimSelector.modemManager.enableModem(modem, !modemEnabled)
                    }

                    Telephony.SimErrorState {
                        id: errorState
                        multiSimManager: voiceSimSelector.modemManager
                        modemPath: modem
                    }
                }
            }

            SectionHeader {
                //% "Call and messages"
                text: qsTrId("settings_networking-he-call_and_messages_sim")
            }

            Item {
                width: parent.width
                height: Theme.paddingMedium
            }

            VoiceSimSelector {
                id: voiceSimSelector
                admin: root.admin
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x

                wrapMode: Text.Wrap

                // TODO: should use presentModemCount, but this is currently returning a false value
                //visible: voiceSimSelector.availableModemCount !== voiceSimSelector.presentModemCount
                visible: voiceSimSelector.availableModemCount !== voiceSimSelector.enabledModems.length

                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor

                //% "Please note that for currently non-active SIM card, last known information is shown."
                text: qsTrId("settings_networking-non_active_sim_note")
            }
        }
    }
}
