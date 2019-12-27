import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0

DisabledByMdmBanner {
    // false -> notify prevented installation, true -> notify prevented uninstallation
    property bool uninstall

    text: uninstall ? //% "Uninstallation disabled by Sailfish Device Manager"
                      qsTrId("jolla-store-la-uninstallation_prevented_by_device_manager")
                    : //% "Installation disabled by Sailfish Device Manager"
                      qsTrId("jolla-store-la-installation_prevented_by_device_manager")
}
