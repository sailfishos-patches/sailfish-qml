import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0

Item {
    readonly property bool error: charging && _error
    readonly property bool full: batteryStatus.status == BatteryStatus.Full
    readonly property bool empty: chargePercentage < 3 // dsme limit for allowing power up
    readonly property bool charging: batteryStatus.chargerStatus == BatteryStatus.Connected
    // Some properties can get set from ChargerTestItem and can't be readonly
    property bool _error: batteryStatus.chargePercentage < 0
    property int chargePercentage: _error ? -1 : batteryStatus.chargePercentage


    BatteryStatus {
        id: batteryStatus
        onChargePercentageChanged: {
            if (actdeadApplication.verboseMode) {
                console.log("batteryStatus.chargePercentage:", chargePercentage)
            }
        }
        onStatusChanged: {
            if (actdeadApplication.verboseMode) {
                console.log("batteryStatus.status:", status)
            }
        }
        onChargerStatusChanged: {
            if (actdeadApplication.verboseMode) {
                console.log("batteryStatus.chargerStatus:", chargerStatus)
            }
        }
    }
}
