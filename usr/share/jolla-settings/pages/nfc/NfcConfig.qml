import QtQml 2.0
import Nemo.DBus 2.0

QtObject {
    id: nfc

    property bool nfcEnabled
    property bool busy: changeTimer.running

    function refreshSettings() {
        nfcSettingsDbus.getEnabled()
    }

    function toggleNfcEnabled() {
        nfcSettingsDbus.setEnabled(!nfcEnabled)
    }

    property Timer changeTimer: Timer {
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

    Component.onCompleted: {
        refreshSettings()
    }
}
