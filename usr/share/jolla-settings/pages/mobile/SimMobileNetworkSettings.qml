import QtQuick 2.0
import MeeGo.QOfono 0.2
import MeeGo.Connman 0.2
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import Sailfish.Settings.Networking 1.0
import org.nemomobile.systemsettings 1.0

Column {
    id: root

    property string modemPath
    property bool showMMSHeader
    property bool showNetworkHeader

    // Access point editors must be kept around after it has been popped
    // off the stack because if the context is active it would first have
    // to deactivate it and only then apply the changes. Context deactivation
    // takes some time and the editor must be kept alive until the changes
    // have been applied.
    property variant _editMobileNetworkPage
    property variant _mmsAccessPointEditor

    width: parent.width

    OfonoNetworkRegistration {
        id: networkRegistration

        modemPath: root.modemPath
    }

    OfonoRadioSettings {
        id: radioSettings

        modemPath: root.modemPath
        onReportError: networkMode.updateValue()
    }

    OfonoNetworkOperatorListModel {
        id: operatorsModel

        modemPath: root.modemPath
    }

    ComboBox {
        //: Mobile data roaming label
        //% "Roaming"
        label: qsTrId("settings_network-bt-data_roaming")
        width: root.width

        //: Roaming disclaimer
        //% "Using mobile data abroad can raise data transfer costs substantially."
        description: qsTrId("settings_network-la-roaming_cost_warning")
        enabled: connectionManager.valid
        property bool rawValue: connectionManager.roamingAllowed

        Component.onCompleted: updateValue()
        onRawValueChanged: updateValue()
        onEnabledChanged: updateValue()
        onCurrentIndexChanged: {
            if (currentIndex >= 0) {
                var allowIt = (currentIndex != 0)
                if (connectionManager.roamingAllowed != allowIt) {
                    connectionManager.roamingAllowed = allowIt
                }
            }
        }

        function updateValue() {
            currentIndex = connectionManager.valid ? (rawValue ? 1 : 0) : -1
        }

        menu: ContextMenu {
            //: Data roaming ComboBox item
            //% "Don't allow"
            MenuItem { text: qsTrId("settings_network-me-roaming_do_not_allow") }
            //: Data roaming ComboBox item
            //% "Always allow"
            MenuItem { text: qsTrId("settings_network-me-roaming_always_allow") }
        }
    }

    ListItem {
        id: dataAccessItem

        enabled: connectionManager.valid && connectionManager.contexts.length > 0

        onClicked: {
            if (!_editMobileNetworkPage) {
                var component = Qt.createComponent(Qt.resolvedUrl("EditMobileNetworkPage.qml"))

                if (component.status === Component.Ready) {
                    _editMobileNetworkPage = component.createObject(root)
                    _editMobileNetworkPage.mobileContextPath = Qt.binding(function() {
                        return connectionManager.contexts.length > 0 ? connectionManager.contexts[0] : ""
                    })
                    _editMobileNetworkPage.title = Qt.binding(function() {
                        return dataAccessLabel.text
                    })
                } else {
                    console.log(component.errorString())
                    return
                }
            }
            pageStack.animatorPush(_editMobileNetworkPage)
        }

        Label {
            id: dataAccessLabel

            //% "Data access point"
            text: qsTrId("settings_network-la-data_access_point")
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            color: dataAccessItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            opacity: dataAccessItem.enabled ? 1.0 : Theme.opacityLow
        }

        OfonoConnMan {
            id: connectionManager

            modemPath: root.modemPath
            filter: "internet"
        }
    }

    //: MMS settings section header
    //% "MMS"
    SectionHeader {
        text: qsTrId("settings_network-he-mms")
        visible: showMMSHeader
    }

    ListItem {
        id: mmsItem

        enabled: mmsConnectionManager.valid && mmsConnectionManager.contexts.length > 0

        onClicked: {
            if (!_mmsAccessPointEditor) {
                var component = Qt.createComponent(Qt.resolvedUrl("EditMobileNetworkPage.qml"))

                if (component.status === Component.Ready) {
                    _mmsAccessPointEditor = component.createObject(root)
                    _mmsAccessPointEditor.mobileContextPath = Qt.binding(function() {
                        return mmsConnectionManager.contexts.length > 0 ? mmsConnectionManager.contexts[0] : ""
                    })
                    _mmsAccessPointEditor.title = Qt.binding(function() {
                        return mmsLabel.text
                    })
                } else {
                    console.log(component.errorString())
                    return
                }
            }
            pageStack.animatorPush(_mmsAccessPointEditor)
        }

        Label {
            id: mmsLabel

            //% "MMS access point"
            text: qsTrId("settings_network-la-mms_access_point")
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            color: mmsItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            opacity: mmsItem.enabled ? 1.0 : Theme.opacityLow
        }

        OfonoConnMan {
            id: mmsConnectionManager

            modemPath: root.modemPath
            filter: "mms"
        }
    }

    //: Network settings section header
    //% "Network"
    SectionHeader {
        text: qsTrId("settings_network-he-network")
        visible: showNetworkHeader
    }

    ComboBox {
        id: networkMode
        enabled: radioSettings.valid && AccessPolicy.cellularTechnologySettingsEnabled
        description: AccessPolicy.cellularTechnologySettingsEnabled
                     ? ""
                       //: %1 is an operating system name without OS suffix
                       //% "Disabled by %1 Device Manager"
                     : qsTrId("settings_network-la-disabled_by_mdm").arg(aboutSettings.baseOperatingSystemName)

        property bool _externalChange: false

        //: Network mode ComboBox label
        //% "Network Mode"
        label: qsTrId("settings_network-bt-network_mode")

        Connections {
            target: radioSettings
            onTechnologyPreferenceChanged: networkMode.updateValue()
            onValidChanged: networkMode.updateValue()
        }

        function updateValue() {
            networkMode._externalChange = true
            if (radioSettings.valid) {
                var itemFound = null
                var tech = radioSettings.technologyPreference
                var items = networkModeMenu.children
                if (items) {
                    for (var i=0; i<items.length; i++) {
                        if (items[i].visible && (items[i].tech === tech || tech === "any")) {
                            itemFound = items[i]
                            break;
                        }
                    }
                }
                if (itemFound) {
                    currentItem = itemFound
                } else {
                    console.log("Radio set to unsupported mode", tech)
                    currentItem = null
                }
            } else {
                currentItem = null
            }
            networkMode._externalChange = false
        }

        onCurrentIndexChanged: {
            if (!networkMode._externalChange && currentItem)
                radioSettings.technologyPreference = currentItem.tech
        }
        Component.onCompleted: updateValue()

        menu: ContextMenu {
            id: networkModeMenu
            MenuItem {
                readonly property string tech: "lte"
                //: Network mode settings ComboBox item for preferring 4G/LTE
                //% "Prefer 4G"
                text: qsTrId("settings_network-me-network_mode_prefer_4G")
                visible: radioSettings.availableTechnologies.indexOf(tech) >= 0
            }
            MenuItem {
                readonly property string tech: "umts"
                //: Network mode settings ComboBox item for prefering 3G/umts
                //% "Prefer 3G"
                text: qsTrId("settings_network-me-network_mode_prefer_3G")
                visible: radioSettings.availableTechnologies.indexOf(tech) >= 0
            }
            MenuItem {
                readonly property string tech: "gsm"
                //: Network mode settings ComboBox item for 2G/gsm only
                //% "2G only"
                text: qsTrId("settings_network-me-network_mode_2G_only")
                visible: radioSettings.availableTechnologies.indexOf(tech) >= 0
            }
        }
    }

    TextSwitch {
        id: networkSelection
        automaticCheck: false
        checked: networkRegistration.mode != "manual"
        enabled: networkRegistration.mode != "auto-only"
        opacity: enabled ? 1.0 : Theme.opacityLow
        //: Network selection TextSwitch text
        //% "Select network automatically"
        text: qsTrId("settings_network-bt_automatic_network_selection")
        onClicked: {
            if (checked) {
                networkRegistration.scan()
                pageStack.animatorPush(Qt.resolvedUrl("SelectNetworkPage.qml"),
                                       { operators: operatorsModel, registration: networkRegistration })
            } else {
                networkRegistration.registration()
            }
        }
    }

    ValueButton {
        id: manualSelection

        enabled: !networkSelection.checked
        //: Manual network selection ComBox label
        //% "Network"
        label: qsTrId("settings_network-bt_manual_network_selection")
        value: {
            if (networkRegistration.status === "registered" || networkRegistration.status === "roaming") {
                return networkRegistration.name
            } else if (networkRegistration.status === "searching") {
                //: Search for mobile network
                //% "Searching..."
                return qsTrId("settings_network-la-searching")
            } else if (networkRegistration.status === "") {
                //: Registering with mobile network
                //% "Registering..."
                return qsTrId("settings_network-la-registering")
            } else if (networkRegistration.status === "denied") {
                //: Mobile network registration denied by network
                //% "Denied"
                return qsTrId("settings_network-la-denied")
            } else if (networkRegistration.status === "unregistered") {
                //: Not registered to any network
                //% "Not registered"
                return qsTrId("settings_network-la-unregistered")
            } else {
                return ""
            }
        }
        onClicked: {
            pageStack.animatorPush(Qt.resolvedUrl("SelectNetworkPage.qml"),
                                   { operators: operatorsModel, registration: networkRegistration })
        }
    }

    AboutSettings {
        id: aboutSettings
    }
}
