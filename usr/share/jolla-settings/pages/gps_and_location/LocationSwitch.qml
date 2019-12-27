import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0

SettingsToggle {
    //% "Location"
    name: qsTrId("settings_location-la-location")
    icon.source: "image://theme/icon-m-location"

    available: AccessPolicy.locationSettingsEnabled
    checked: locationSettings.locationEnabled

    onToggled: {
        if (!AccessPolicy.locationSettingsEnabled) {
            errorNotification.notify(SettingsControlError.BlockedByAccessPolicy)
        } else {
            var newState = !checked
            locationSettings.locationEnabled = newState

            // allow to exit gps flight mode if location is explicitly enabled, see location.qml
            if (newState && locationSettings.gpsEnabled) {
                locationSettings.gpsFlightMode = false
            }
        }
    }

    LocationConfiguration {
        id: locationSettings
    }
}
