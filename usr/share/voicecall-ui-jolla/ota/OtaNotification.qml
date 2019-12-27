import QtQuick 2.0
import org.nemomobile.notifications 1.0
import org.nemomobile.dbus 2.0

Notification {
    id: otaNotification

    isTransient: true
    urgency: Notification.Critical

    property var simManager: telephony.simManager
    property bool multipleAvailableSims: simManager.valid && simManager.availableModemCount > 1

    property var dbusInterface: DBusInterface {
        signalsEnabled: true
        bus: DBus.SystemBus
        service: "org.nemomobile.provisioning"
        iface: "org.nemomobile.provisioning.interface"
        path: "/"

        signal apnProvisioningSucceeded(string imsi, string path)
        signal apnProvisioningPartiallySucceeded(string imsi, string path)
        signal apnProvisioningFailed(string imsi, string path)

        function serviceProviderName(modemPath) {
            return simManager.simNames[simManager.indexOfModem(modemPath)]
        }

        onApnProvisioningSucceeded: {
            if (multipleAvailableSims) {
                //: Contains SIM name, e.g. "SIM1 | Operator name" or user defined string
                //% "Access point settings saved for %0"
                otaNotification.previewBody = qsTrId("voicecall-la-apn_serviceprovider_settings_saved").arg(serviceProviderName(path))
            } else {
                //% "Access point settings saved"
                otaNotification.previewBody = qsTrId("voicecall-la-apn_settings_saved")
            }
            otaNotification.publish()
        }
        onApnProvisioningPartiallySucceeded: {
            if (multipleAvailableSims) {
                //: Contains SIM name, e.g. "SIM1 | Operator name" or user defined string
                //% "Access point settings partially saved for %0"
                otaNotification.previewBody = qsTrId("voicecall-la-apn_serviceprovider_settings_partially_saved").arg(serviceProviderName(path))
            } else {
                //% "Access point settings partially saved"
                otaNotification.previewBody = qsTrId("voicecall-la-apn_settings_partially_saved")
            }
            otaNotification.publish()
        }
        onApnProvisioningFailed: {
            if (multipleAvailableSims) {
                //: Contains SIM name, e.g. "SIM1 | Operator name" or user defined string
                //% "Failed to save received access point settings for %0"
                otaNotification.previewBody = qsTrId("voicecall-la-apn_serviceprovider_failed_to_save_apn_settings").arg(serviceProviderName(path))
            } else {
                //% "Failed to save received access point settings"
                otaNotification.previewBody = qsTrId("voicecall-la-apn_failed_to_save_apn_settings")
            }
            otaNotification.publish()
        }
    }
}
