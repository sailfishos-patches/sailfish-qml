import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import Sailfish.Telephony 1.0
import Sailfish.Settings.Networking 1.0
import Nemo.Connectivity 1.0
import Nemo.DBus 2.0
import com.jolla.settings 1.0

SimDependentSettingsToggle {
    id: mobileSwitch

    property bool expectedState
    readonly property string operatorName: mobileData.serviceProviderName || mobileData.connectionName

    //% "Mobile data"
    name: qsTrId("settings_networking-mobile_data")
    activeText: operatorName
    icon.source: Telephony.multiSimSupported && simManager.activeSim >= 0 && simManager.activeSim <= 1
                 ? "image://theme/icon-m-data-sim-" + (simManager.activeSim + 1)
                 : "image://theme/icon-m-data-traffic"
    available: simToggleAvailable
               && AccessPolicy.mobileNetworkSettingsEnabled
               && !mobileData.offlineMode
    active: mobileData.status === MobileDataConnection.Online
               || mobileData.status === MobileDataConnection.Limited
    checked: mobileData.valid && enabled && mobileData.autoConnect
    busy: tapTimer.running && expectedState !== mobileData.autoConnect
    errorNotification.icon: "icon-system-connection-mobile"

    menu: ContextMenu {
        SettingsMenuItem {
            onClicked: mobileSwitch.goToSettings()
        }

        MenuItem {
            //% "Data counters"
            text: qsTrId("settings_networking-data_counters")
            onClicked: settingsApp.call("showPage", ["system_settings/info/datacounters"])
        }
    }

    onToggled: {
        if (handleSimSettingsToggled()) {
            return
        }

        if (!AccessPolicy.mobileNetworkSettingsEnabled) {
            errorNotification.notify(SettingsControlError.BlockedByAccessPolicy)
        } else if (mobileData.offlineMode) {
            errorNotification.notify(SettingsControlError.BlockedByFlightMode)
        } else if (mobileData.valid) {
            expectedState = !mobileData.autoConnect
            mobileData.autoConnect = expectedState
            if (!expectedState) {
                mobileData.disconnect()
            }
            tapTimer.restart()
        } else {
            connectionSelector.openConnection()
        }
    }

    Timer {
        id: tapTimer
        interval: 2000
    }

    NetworkingMobileDataConnection {
        id: mobileData
        objectName: "EnableSwitch_MobileDataConnection"
        useDefaultModem: true
    }


    Behavior on opacity { FadeAnimation { } }

    DBusInterface {
        id: connectionSelector

        service: "com.jolla.lipstick.ConnectionSelector"
        path: "/"
        iface: "com.jolla.lipstick.ConnectionSelectorIf"

        function openConnection() {
            call('openConnectionNow', 'cellular')
        }
    }

    DBusInterface {
        id: settingsApp

        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"
    }
}
