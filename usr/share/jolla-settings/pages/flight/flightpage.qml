import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import Sailfish.Settings.Networking 1.0
import org.freedesktop.contextkit 1.0

Page {
    id: root

    Column {
        width: parent.width
        enabled: !disabledByMdmBanner.active
        PageHeader {
            //% "Airplane mode"
            title: qsTrId("settings_flight-he-flight-mode")
        }

        DisabledByMdmBanner {
            id: disabledByMdmBanner
            active: !AccessPolicy.flightModeToggleEnabled
        }

        IconTextSwitch {
            id: flightSwitch

            property string entryPath: "system_settings/connectivity/flight/enable_switch"

            automaticCheck: false
            enabled: AccessPolicy.flightModeToggleEnabled
            checked: flightMode.active
            //% "Airplane mode"
            text: qsTrId("settings_flight-la-flight-mode")
            description: capabilityDataContextProperty.value || capabilityDataContextProperty.value === undefined
            // Description for devices with mobile data capability
            //% "Switches off cellular, WLAN and Bluetooth radios for safe usage in restricted environments. WLAN or Bluetooth can be switched on separately even in airplane mode if allowed in restricted environment."
                         ? qsTrId("settings_flight-la-flight-mode-description")
                           // Description for devices without mobile data capability
                           //% "Switches off WLAN and Bluetooth radios for safe usage in restricted environments. WLAN or Bluetooth can be switched on separately even in airplane mode if allowed in restricted environment."
                         : qsTrId("settings_flight-la-flight-mode-description_non-mobile-data")
            icon.source: "image://theme/icon-m-airplane-mode"

            onClicked: {
                busy = true
                flightMode.setActive(!flightSwitch.checked)
            }
        }
        FlightMode {
            id: flightMode
            onActiveChanged: {
                flightSwitch.busy = false
                flightSwitch.checked = active
            }
        }
    }

    ContextProperty {
        id: capabilityDataContextProperty
        key: "Cellular.CapabilityData"
    }
}

