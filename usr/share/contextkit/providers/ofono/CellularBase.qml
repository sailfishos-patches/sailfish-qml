/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA
 *
 * http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
 */

import QtQml 2.2
import MeeGo.QOfono 0.2
import MeeGo.Connman 0.2
import Nemo.DBus 2.0
import Sailfish.Telephony 1.0
import org.freedesktop.contextkit 1.0
import org.nemomobile.ofono 1.0

ContextPropertyBase {
    id: root

    property string modemPath
    property SimManager telephonySimManager: SimManager {}

    property var _connectionManager
    property var _networkReg
    property var _networkOp
    property var _ofonoSimManager
    property var _simInfo
    property var _simToolkit
    property var _voiceCallManager

    function _getConnectionManager() {
        if (!_connectionManager) {
            _connectionManager = connectionManagerComponent.createObject(root)
        }
        return _connectionManager
    }

    function _getNetworkReg() {
        if (!_networkReg) {
            _networkReg = networkRegistrationComponent.createObject(root)
        }
        return _networkReg
    }

    function _getNetworkOp() {
        if (!_networkOp) {
            _networkOp = networkOperatorComponent.createObject(root)
        }
        return _networkOp
    }

    function _getOfonoSimManager() {
        if (!_ofonoSimManager) {
            _ofonoSimManager = ofonoSimManagerComponent.createObject(root)
        }
        return _ofonoSimManager
    }

    function _getSimInfo() {
        if (!_simInfo) {
            _simInfo = simInfoComponent.createObject(root)
        }
        return _simInfo
    }

    function _getSimToolkit() {
        if (!_simToolkit) {
            _simToolkit = simToolkitComponent.createObject(root)
        }
        return _simToolkit
    }

    function _getVoiceCallManager() {
        if (!_voiceCallManager) {
            _voiceCallManager = voiceCallManagerComponent.createObject(root)
        }
        return _voiceCallManager
    }

    propertyValue: {
    switch (propertyName) {

    case "SignalStrength":
        return _getNetworkReg().valid ? _getNetworkReg().strength : 0
    case "DataTechnology":
        return _getNetworkReg().dataTechnologyText
    case "RegistrationStatus":  // fall through
    case "Status":
        return _getNetworkReg().networkStatusText
    case "Sim":
        return telephonySimManager.modemHasPresentSim(modemPath) ? "present" : "absent"
    case "Technology":
        return _getNetworkReg().technologyText
    case "SignalBars":
        return _getNetworkReg().valid ? _getNetworkReg().signalBars : 0

    case "CellName":
        return _getNetworkReg().valid ? _getNetworkReg().cellId : ""
    case "NetworkName": // fall through
    case "ExtendedNetworkName":
        return _getNetworkReg().valid
                ? _getNetworkReg().name || _getNetworkOp().name
                : ""

    case "SubscriberIdentity":
        return _getOfonoSimManager().valid ? _getOfonoSimManager().subscriberIdentity : ""
    case "CurrentMCC":
        return _getNetworkReg().valid ? _getNetworkReg().mcc : "0"
    case "CurrentMNC":
        return _getNetworkReg().valid ? _getNetworkReg().mnc : "0"
    case "HomeMCC":
        return _getOfonoSimManager().valid ? _getOfonoSimManager().mobileCountryCode : "0"
    case "HomeMNC":
        return _getOfonoSimManager().valid ? _getOfonoSimManager().mobileNetworkCode : "0"

    case "StkIdleModeText":
        return _getSimToolkit().idleModeText
    case "MMSContext":
        return _getConnectionManager().mmsContext
    case "DataRoamingAllowed":
        return _getConnectionManager().roamingAllowed
    case "GPRSAttached":
        return _getConnectionManager().attached

    case "CapabilityVoice":
        return telephonySimManager.availableModems.length > 0
    case "CapabilityData":
        return telephonySimManager.availableModems.length > 0
    case "CallCount":
        return _getVoiceCallManager().calls.length

    case "ModemPath":
        return modemPath

    case "ServiceProviderName":
        return _getSimInfo().serviceProviderName
    case "CachedCardIdentifier":
        return _getSimInfo().cardIdentifier
    case "CachedSubscriberIdentity":
        return _getSimInfo().subscriberIdentity

    default:
        console.log("Unknown property:", propertyName)
        return undefined
    }
    }

    Component {
        id: connectionManagerComponent

        OfonoConnMan {
            id: connectionManager

            property string mmsContext

            property var _mmsInstantiator: Instantiator {
                model: root.subscribed ? connectionManager.contexts : []

                delegate: OfonoContextConnection {
                    property bool _isMmsContext: type === "mms" && messageCenter.length > 0

                    contextPath: modelData

                    on_IsMmsContextChanged: {
                        if (_isMmsContext) {
                            connectionManager.mmsContext = contextPath
                        } else if (connectionManager.mmsContext == contextPath) {
                            connectionManager.mmsContext = ""
                        }
                    }
                }
            }

            modemPath: root.subscribed ? root.modemPath : ""

        }
    }

    Component {
        id: networkRegistrationComponent

        OfonoNetworkRegistration {
            id: network

            property string networkStatusText: {
                if (network.valid) {
                    if (!telephonySimManager.modemHasPresentSim(modemPath)) {
                        return "no-sim"
                    }
                    switch (status) {
                    case "unregistered":
                        return "disabled"
                    case "registered":
                        return "home"
                    case "searching":
                    case "unknown":
                        return "offline"
                    case "denied":
                        return "forbidden"
                    case "roaming":
                        return "roam"
                    }
                }
                return "disabled"
            }

            property string dataTechnologyText: network.valid && _networkTechnologies[network.technology]
                                                ? _networkTechnologies[network.technology].dataTech
                                                : "unknown"

            property string technologyText: network.valid && _networkTechnologies[network.technology]
                                            ? _networkTechnologies[network.technology].tech
                                            : "unknown"

            // 0-5 range
            property int signalBars: (strength + 19) / 20

            property var _networkTechnologies: {
                "gsm": { "tech": "gsm", "dataTech": "gprs" },
                "edge": { "tech": "gsm", "dataTech": "egprs" },
                "hspa": { "tech": "umts",  "dataTech": "hspa" },
                "umts": { "tech": "umts",  "dataTech": "umts"},
                "lte": { "tech": "lte",  "dataTech": "lte"}
            };

            modemPath: root.subscribed ? root.modemPath : ""
        }
    }

    Component {
        id: networkOperatorComponent

        OfonoNetworkOperator {
            id: operator

            operatorPath: root.subscribed ? network.currentOperatorPath : ""
        }
    }

    Component {
        id: ofonoSimManagerComponent

        OfonoSimManager {
            id: ofonoSimManager

            modemPath: root.subscribed ? root.modemPath : ""
        }
    }

    Component {
        id: simInfoComponent

        OfonoSimInfo {
            id: simInfo

            modemPath: root.subscribed ? root.modemPath : ""
        }
    }

    Component {
        id: simToolkitComponent

        DBusInterface {
            id: simToolkit

            property string idleModeText

            bus: DBus.SystemBus
            service: "org.ofono"
            path: root.modemPath
            iface: "org.ofono.SimToolkit"
            signalsEnabled: root.subscribed

            function propertyChanged(property, value) {
                if (property === "IdleModeText") {
                    idleModeText = value
                }
            }

            Component.onCompleted: {
                if (!root.subscribed || root.modemPath.length === 0) {
                    return
                }
                call("GetProperties", [], function(properties) {
                    simToolkit.idleModeText = properties["IdleModeText"]
                })
            }
        }
    }

    Component {
        id: voiceCallManagerComponent

        OfonoVoiceCallManager {
            id: voiceCallManager

            property var calls: []

            Component.onCompleted: calls = getCalls()
            onCallAdded: {
                if (calls.indexOf(call) < 0) {
                    calls.push(call)
                }
            }
            onCallRemoved: {
                var i = calls.indexOf(call)
                if (i >= 0) {
                    calls.splice(i, 1)
                }
            }
        }
    }
}
