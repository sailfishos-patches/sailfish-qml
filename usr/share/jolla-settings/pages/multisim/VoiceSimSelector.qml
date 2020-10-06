/*
    Copyright (C) 2016 Jolla Ltd.
    Contact: Raine Mäkeläinen <raine.makelainen@jolla.com>
*/

import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0

SimSelectorBase {
    id: root

    readonly property bool alwaysAsk: Telephony.voiceSimUsageMode === Telephony.AlwaysAskSim
    property bool admin

    width: parent.width
    height: comboBox.height
    enabled: active && admin
    controlType: SimManagerType.Voice
    modemManager.objectName: "VoiceSimSelector"

    onActiveSimChanged: proxyModel.update()

    ComboBox {
        id: comboBox

        readonly property bool forceActiveSimSelection: (root.simCount === 1 || root.modemManager.enabledModems.length < 2)

        width: parent.width
        //% "Use SIM card"
        label: qsTrId("settings_networking-la-use_sim_card")
        //% "Select SIM card used for dialing calls and sending messages. You can also access the setting in Events shortcut panel."
        description: qsTrId("settings_networking-la-select_active_sim")

        enabled: !forceActiveSimSelection && root.simCount > 1

        menu: ContextMenu {
            id: contextMenu

            Connections {
                target: root.modemManager.modemSimModel
                onUpdated: proxyModel.update()
            }

            ListModel {
                id: proxyModel

                property int selectIndex

                function select(index) {
                    if (selectIndex === index) {
                        return
                    }

                    for (var i = 0; i < count; ++i) {
                        setProperty(i, "selectedItem", false)
                    }
                    if (index >= 0 && index < count) {
                        setProperty(index, "selectedItem", true)
                    }
                    selectIndex = index
                }

                function update() {
                    if (!root.modemManager.ready) {
                        return
                    }

                    var count = root.modemManager.modemSimModel.count
                    var canUpdate = (count === (proxyModel.count - 1))
                    var currentIndex = -1
                    for (var i = 0; i < count; ++i) {
                        var item = root.modemManager.modemSimModel.get(i)
                        var isSelected = ((root.activeSim === i) && (!alwaysAsk || comboBox.forceActiveSimSelection))
                        if (isSelected) {
                            currentIndex = i
                        }

                        if (canUpdate) {
                            proxyModel.setProperty(i, "title", item.simName || "")
                        } else {
                            proxyModel.append({
                                                  "isSelectableModem": true,
                                                  "selectedItem": isSelected,
                                                  "title": item.simName || ""
                                              })
                        }
                    }

                    if (canUpdate) {
                        select(currentIndex)
                    } else {
                        // First update adds "Always ask" option

                        //: Always ask option in Voice and Messages ComboBox (Settings -> Sim)
                        //% "Always ask"
                        var alwaysAskText = qsTrId("settings_networking_generic_always_ask")
                        proxyModel.append({
                                              "isSelectableModem": false,
                                              "selectedItem": alwaysAsk,
                                              "title": alwaysAskText
                                          })
                        repeater.model = proxyModel
                    }

                    if (alwaysAsk && !comboBox.forceActiveSimSelection) {
                        currentIndex = proxyModel.count - 1
                    }

                    if (currentIndex >= 0) {
                        comboBox.currentIndex = currentIndex
                    }
                }
            }

            Repeater {
                id: repeater
                delegate: MenuItem {
                    down: mouseBlocker.pressed && mouseBlocker.containsMouse
                    highlighted: down || selectedItem
                    text: model.title

                    // Do not let MenuItem to trigger clicked signal as the ContextMenu updates
                    // currentIndex automatically. Update ComboBox.currentIndex only when active
                    // SIM has changed.
                    // Active SIM card is not updated if PIN code is needed / not given.
                    MouseArea {
                        id: mouseBlocker
                        anchors.fill: parent
                        onClicked: {
                            if (isSelectableModem) {
                                root.modemManager.setActiveSim(index)
                            }
                            comboBox.currentIndex = index
                            proxyModel.select(index)

                            Telephony.voiceSimUsageMode = (isSelectableModem ? Telephony.ActiveSim : Telephony.AlwaysAskSim)
                            contextMenu.close()
                        }
                    }
                }
            }
        }
    }
}
