import QtQml 2.0
import Nemo.DBus 2.0

QtObject {
    id: nfc

    property bool nfcEnabled
    property bool nfcBluetoothStaticHandoverEnabled
    property bool nfcBluetoothStaticHandoverSupported
    property bool busy: changeTimer.running
    property bool neardBusy: neardChangeTimer.running

    function refreshSettings() {
        nfcSettingsDbus.getEnabled()
        neardSettingsDbus.getBluetoothStaticHandover()
    }

    function toggleNfcEnabled() {
        nfcSettingsDbus.setEnabled(!nfcEnabled)
    }

    function toggleNfcBluetoothStaticHandoverEnabled() {
        neardSettingsDbus.setBluetoothStaticHandover(!nfcBluetoothStaticHandoverEnabled)
    }

    property Timer changeTimer: Timer {
        interval: 2000
    }

    property Timer neardChangeTimer: Timer {
        interval: 2000
    }

    property QtObject nfcSettingsDbus: DBusInterface {
        bus: DBus.SystemBus
        service: 'org.sailfishos.nfc.settings'
        path: '/'
        iface: 'org.sailfishos.nfc.Settings'
        signalsEnabled: true

        function enabledChanged(enabled) {
            changeTimer.stop()
            nfc.nfcEnabled = enabled
        }

        function getEnabled() {
            changeTimer.restart()
            call("GetEnabled", undefined, function (enabled) {
                // Success state
                changeTimer.stop()
                nfc.nfcEnabled = enabled
            }, function() {
                // Failure state
                nfcEnabled = false
                changeTimer.stop()
            })
        }

        function setEnabled(enabled) {
            changeTimer.restart()
            call("SetEnabled", enabled, undefined, function () {
                // Failure state
                nfcEnabled = false
                changeTimer.stop()
            })
        }
    }

    property QtObject neardSettingsDbus: DBusInterface {
        bus: DBus.SystemBus
        service: 'org.neard'
        path: '/'
        iface: 'org.sailfishos.neard.Settings'
        signalsEnabled: true

        function bluetoothStaticHandoverChanged(enabled) {
            neardChangeTimer.stop()
            nfc.nfcBluetoothStaticHandoverEnabled = enabled
        }

        function getBluetoothStaticHandover() {
            neardChangeTimer.restart()
            call("GetBluetoothStaticHandover", undefined, function (enabled) {
                // Success state
                neardChangeTimer.stop()
                nfc.nfcBluetoothStaticHandoverEnabled = enabled
                nfcBluetoothStaticHandoverSupported = true
            }, function() {
                // Failure state
                nfcBluetoothStaticHandoverEnabled = false
                nfcBluetoothStaticHandoverSupported = false
                neardChangeTimer.stop()
            })
        }

        function setBluetoothStaticHandover(enabled) {
            neardChangeTimer.restart()
            call("SetBluetoothStaticHandover", enabled, undefined, function () {
                // Failure state
                nfcBluetoothStaticHandoverEnabled = false
                neardChangeTimer.stop()
            })
        }
    }

    Component.onCompleted: {
        refreshSettings()
    }
}
