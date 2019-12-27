import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import Sailfish.Settings.Networking 1.0
import com.jolla.settings 1.0

SimDependentSettingsToggle {
    id: connectionSharingSwitch

    //: WLAN hotspot
    //% "Hotspot"
    name: qsTrId("settings_networking-la-hotspot_only")
    activeText: wifiTethering.identifier
    icon.source: "image://theme/icon-m-wlan-hotspot"

    active: wifiTethering.active
    busy: wifiTethering.busy
    checked: wifiTethering.active
    available: simToggleAvailable
               && AccessPolicy.internetSharingEnabled
               && !wifiTethering.offlineMode
               && wifiTethering.roamingAllowed
               && wifiTethering.identifier.length > 0

    onToggled: {
        if (wifiTethering.active) {
            wifiTethering.stopTethering()
            return
        }
        if (handleSimSettingsToggled()
                && simManager.availableSimCount === 0) {
            // Continue if there is a SIM but currently not connected; tethering can still be
            // enabled in this case.
            return
        }

        if (!AccessPolicy.internetSharingEnabled) {
            errorNotification.notify(SettingsControlError.BlockedByAccessPolicy)
        } else if (wifiTethering.offlineMode) {
            errorNotification.notify(SettingsControlError.BlockedByFlightMode)
        } else if (!wifiTethering.roamingAllowed) {
            //% "Roaming not enabled"
            errorNotification.notify(qsTrId("settings_networking-la-roaming_not_enabled"))
        } else if (wifiTethering.identifier.length === 0) {
            errorNotification.notify(SettingsControlError.ConnectionSetupRequired)
            goToSettings()
        } else {
            if (wifiTethering.passphrase.length === 0) {
                wifiTethering.passphrase = wifiTethering.generatePassphrase()
            }
            if (!wifiTethering.autoConnect) {
                wifiTethering.requestMobileData()
            }
            wifiTethering.startTethering()
        }
    }

    MobileDataWifiTethering {
        id: wifiTethering
    }
}
