import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: usb

    property bool itemsPopulated: false

    USBSettings {
        id: usbSettings
        onAvailableModesChanged: createItems()
        onConfigModeChanged: updateCurrentItem()
        onTargetModeChanged: {
            delayActivationMessageTimer.restart()
            if (targetMode === usbSettings.MODE_UNDEFINED) {
                // usb-mode indicates cable disconnect, but
                // chargerStatus might remain connected for
                // a while longer and needs to be ignored.
                ignoreChargerStatusTimer.start()
            }
        }
    }

    readonly property var usbModes: [
        {
            mode: usbSettings.MODE_CHARGER,
            //% "Charger"
            menuText: qsTrId("settings_usb-me-charger"),
            // Dedicated charger but net effect is charging only
            preparingLabel: qsTrId("settings_usb-la-preparing-charging"),
            currentLabel: qsTrId("settings_usb-la-charging")
        },{
            mode: usbSettings.MODE_CHARGING,
            //% "Charging only"
            menuText: qsTrId("settings_usb-me-charging"),
            //% "Preparing for charging only"
            preparingLabel: qsTrId("settings_usb-la-preparing-charging"),
            //% "Currently charging only"
            currentLabel: qsTrId("settings_usb-la-charging")
        },{
            mode: usbSettings.MODE_MASS_STORAGE,
            //% "Mass storage"
            menuText: qsTrId("settings_usb-me-mass_storage"),
            //% "Preparing for mass storage mode"
            preparingLabel: qsTrId("settings_usb-la-preparing-mass_storage"),
            //% "Mass storage mode in use"
            currentLabel: qsTrId("settings_usb-la-mass_storage")
        },{
            mode: usbSettings.MODE_MTP,
            //% "Media transfer (MTP)"
            menuText: qsTrId("settings_usb-me-mtp"),
            //% "Preparing for media transfer (MTP) mode"
            preparingLabel: qsTrId("settings_usb-la-preparing-mtp"),
            //% "Media transfer (MTP) mode in use"
            currentLabel: qsTrId("settings_usb-la-mtp")
        },{
            mode: usbSettings.MODE_CONNECTION_SHARING,
            //% "USB tethering"
            menuText: qsTrId("settings_usb-me-connshare"),
            //% "Preparing for USB tethering"
            preparingLabel: qsTrId("settings_usb-la-preparing-connshare"),
            //% "USB tethering"
            currentLabel: qsTrId("settings_usb-la-connshare")
        },{
            mode: usbSettings.MODE_DEVELOPER,
            //% "Developer Mode"
            menuText: qsTrId("settings_usb-me-developer"),
            //% "Preparing for developer mode"
            preparingLabel: qsTrId("settings_usb-la-preparing-developer"),
            //% "Developer mode in use"
            currentLabel: qsTrId("settings_usb-la-developer")
        },{
            mode: usbSettings.MODE_PC_SUITE,
            //% "PC connection mode"
            menuText: qsTrId("settings_usb-me-pc_suite"),
            //% "Preparing for PC connection mode"
            preparingLabel: qsTrId("settings_usb-la-preparing-pc_suite"),
            //% "PC connection mode in use"
            currentLabel: qsTrId("settings_usb-la-pc_suite")
        },{
            mode: usbSettings.MODE_ADB,
            //% "Adb mode"
            menuText: qsTrId("settings_usb-me-adb"),
            //% "Preparing for Android™ debug bridge mode"
            preparingLabel: qsTrId("settings_usb-la-preparing-adb"),
            //% "Android™ debug bridge mode"
            currentLabel: qsTrId("settings_usb-la-adb")
        },{
            mode: usbSettings.MODE_DIAG,
            //% "Diag mode"
            menuText: qsTrId("settings_usb-me-diag"),
            //% "Preparing for diag mode"
            preparingLabel: qsTrId("settings_usb-la-preparing-diag"),
            //% "Diag mode"
            currentLabel: qsTrId("settings_usb-la-diag")
        },{
            mode: usbSettings.MODE_ASK,
            //% "Always ask"
            menuText: qsTrId("settings_usb-me-always_ask"),
            // Asking from user is effectively the same as charging only
            preparingLabel: qsTrId("settings_usb-la-preparing-charging"),
            currentLabel: qsTrId("settings_usb-la-charging")
        },{
            mode: usbSettings.MODE_HOST,
            //% "Host mode"
            menuText: qsTrId("settings_usb-me-host"),
            //% "Preparing for host mode"
            preparingLabel: qsTrId("settings_usb-la-preparing-host"),
            //% "Host mode"
            currentLabel: qsTrId("settings_usb-la-host"),
        }
    ]

    property list<PolicyValue> policies: [
        PolicyValue {
            policyType: PolicyValue.UsbMassStorageEnabled
            objectName: usbSettings.MODE_MASS_STORAGE
        },
        PolicyValue {
            policyType: PolicyValue.UsbDeveloperModeEnabled
            objectName: usbSettings.MODE_DEVELOPER
        },
        PolicyValue {
            policyType: PolicyValue.UsbMtpEnabled
            objectName: usbSettings.MODE_MTP
        },
        PolicyValue {
            policyType: PolicyValue.UsbHostEnabled
            objectName: usbSettings.MODE_HOST
        },
        PolicyValue {
            policyType: PolicyValue.UsbConnectionSharingEnabled
            objectName: usbSettings.MODE_CONNECTION_SHARING
        },
        PolicyValue {
            policyType: PolicyValue.UsbDiagnosticModeEnabled
            objectName: usbSettings.MODE_DIAG
        },
        PolicyValue {
            policyType: PolicyValue.UsbAdbEnabled
            objectName: usbSettings.MODE_ADB
        }
    ]

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content

            spacing: Theme.paddingLarge
            width: parent.width

            PageHeader {
                //% "USB"
                title: qsTrId("settings_usb-he-usb")
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin*2
                x: Theme.horizontalPageMargin
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                text: {
                    // Hide initial unknown state
                    if (usbSettings.currentMode.length == 0 || usbSettings.targetMode.length == 0) {
                        return ""
                    }

                    // Handle stable state
                    if (usbSettings.currentMode == usbSettings.targetMode) {
                        // Connected states are handled as-is
                        if (usbSettings.currentMode != usbSettings.MODE_UNDEFINED) {
                            return translatedModeDescription(usbSettings.currentMode)
                        }
                        // Disconnected state might be equated with charging-only
                        if (!ignoreChargerStatusTimer.running) {
                            if (batteryStatus.chargerStatus == BatteryStatus.Connected) {
                                // Dedicated charger might not show up as "usb" device. In which
                                // case usb-mode based heuristics are not applicable -> if battery
                                // is getting charged, indicate charger despite undefined usb-mode.
                                return qsTrId("settings_usb-la-charging")
                            }
                        }
                    }

                    // Handle disconnected state / hide disconnect transition
                    if (usbSettings.targetMode == usbSettings.MODE_UNDEFINED) {
                        //% "Currently not connected"
                        return qsTrId("settings_usb-la-not_connected")
                    }

                    // Hide short living transitions
                    if (delayActivationMessageTimer.running) {
                        // Retain current label
                        return text
                    }

                    // Show activation transitions
                    return translatedModeActivation(usbSettings.targetMode)
                }
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin*2
                x: Theme.horizontalPageMargin
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                visible: text !== ""
                text: {
                    var disabledModes = []
                    var policies = usb.policies

                    for (var i = 0; i < policies.length; ++i) {
                        var policy = policies[i]
                        if (!policy.value && modeIsSupported(policy.objectName)) {
                            disabledModes.push(translatedModeName(policy.objectName))
                        }
                    }
                    if (disabledModes.length > 0) {
                        //: %1 is operating system name without OS suffix
                        //% "USB modes disabled by %1 Device Manager: "
                        return qsTrId("settings_usb_la-modes-disabled-by-mdm")
                            .arg(aboutSettings.baseOperatingSystemName) + disabledModes.join(Format.listSeparator)
                    }
                    return ""
                }
            }

            Label {
                width: parent.width - Theme.horizontalPageMargin*2
                x: Theme.horizontalPageMargin
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                visible: usbSettings.configMode !== usbSettings.MODE_ASK
                        && usbSettings.currentMode !== usbSettings.MODE_UNDEFINED
                        && usbSettings.currentMode !== usbSettings.MODE_BUSY
                        && usbSettings.currentMode !== usbSettings.configMode

                //% "Reconnect the USB cable to take the selected mode into use"
                text: qsTrId("settings_usb_la-reconnect-to-change-mode")
            }

            ComboBox {
                id: comboBox
                width: parent.width
                //% "Default USB mode"
                label: qsTrId("settings_usb-la-default_usb_mode")
                value: translatedModeName(usbSettings.configMode)
                onCurrentItemChanged: {
                    if (itemsPopulated && currentItem) {
                        if (usbSettings.configMode != currentItem.mode) {
                            usbSettings.configMode = currentItem.mode
                        }
                    }
                }

                menu: ContextMenu {
                    Repeater {
                        model: ListModel { id: itemModel }

                        MenuItem {
                            readonly property string mode: model.mode
                            readonly property string configMode: usbSettings.configMode
                            text: model.text
                        }
                    }
                }
            }
        }
    }

    BatteryStatus {
        id: batteryStatus

        onChargerStatusChanged: {
            if (chargerStatus == BatteryStatus.Connected) {
                // chargerStatus indicates cable connect - delay
                // reaction briefly to allow time for usb-mode
                // changes to happen.
                ignoreChargerStatusTimer.start()
            }
        }
    }

    function updateCurrentItem()
    {
        var index = -1
        for (var i = 0; i < itemModel.count; i++) {
            if (itemModel.get(i).mode == usbSettings.configMode) {
                index = i
                break
            }
        }
        comboBox.currentIndex = index
    }

    function createItems()
    {
        itemsPopulated = false
        itemModel.clear()

        var askFound = false
        var chargingFound = false
        var modes = usbSettings.availableModes
        for (var i = 0; i < modes.length; i++) {
            var mode = modes[i]
            createItem(i, mode)
            chargingFound |= (mode == usbSettings.MODE_CHARGING)
            askFound |= (mode == usbSettings.MODE_ASK)
        }

        if (!chargingFound) {
            createItem(0, usbSettings.MODE_CHARGING)
        }
        if (!askFound) {
            createItem(0, usbSettings.MODE_ASK)
        }

        itemsPopulated = true
        updateCurrentItem()
    }

    function createItem(index, mode)
    {
        var text = translatedModeName(mode)
        itemModel.insert(index, {"mode": mode, "text": text})
    }

    function modeIsSupported(mode)
    {
        return usbSettings.supportedModes.indexOf(mode) >= 0
    }

    function translatedModeDescription(mode)
    {
        for (var j = 0; j < usbModes.length; ++j) {
            var data = usbModes[j]
            if (data.mode === mode) {
                if (!data.currentLabel) {
                    break
                }
                return data.currentLabel
            }
        }

        // No localized description. Use name as fallback.
        return translatedModeName(mode)
    }

    function translatedModeActivation(mode)
    {
        for (var j = 0; j < usbModes.length; ++j) {
            var data = usbModes[j]
            if (data.mode === mode) {
                if (!data.preparingLabel) {
                    break
                }
                return data.preparingLabel
            }
        }

        // No localized description. Use name based fallback
        var text = translatedModeName(mode)
        //: Used for indicating a pending usb-mode change - %1 is the target mode name
        //% "Preparing %1"
        return qsTrId("settings_usb-la-preparing_mode").arg(text)
    }

    function translatedModeName(mode) {
        for (var j = 0; j < usbModes.length; ++j) {
            var data = usbModes[j]
            if (data.mode === mode) {
                if (!data.menuText) {
                    break;
                }
                return data.menuText
            }
        }
        //: Used for unkown custom modes - %1 is untranslated mode name as-is
        //% "Mode %1"
        return qsTrId("settings_usb-me-other").arg(mode)
    }

    Timer {
        id: ignoreChargerStatusTimer

        interval: 1000
    }

    Timer {
        id: delayActivationMessageTimer

        // The intent is to omit flashes of "Preparing for..."
        // messages. The delay should be long enough to cover
        // average developer mode activation, and short enough
        // to give user feeling of progress during for example
        // mtp mode activation.
        interval: 800
    }

    Component.onCompleted: createItems()

    AboutSettings {
        id: aboutSettings
    }
}
