import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import org.nemomobile.systemsettings 1.0

SettingsToggle {
    // Lock mode from user point of view
    readonly property bool portraitLock: displaySettings.orientationLock == "portrait" || displaySettings.orientationLock == "portrait-inverted"
    readonly property bool landscapeLock: displaySettings.orientationLock == "landscape" || displaySettings.orientationLock == "landscape-inverted"

    name: portraitLock
          ? //% "Portrait"
            qsTrId("settings_system-orientation_portrait")
          : landscapeLock
            ? //% "Landscape"
              qsTrId("settings_system-orientation_landscape")
            : //: Abbreviated form of settings_system-orientation_lock
              //% "Orientation"
              qsTrId("settings_system-orientation_lock_short")

    icon.source: portraitLock
                 ? "image://theme/icon-m-device-portrait"
                 : landscapeLock
                    ? "image://theme/icon-m-device-landscape"
                    : "image://theme/icon-m-orientation-lock"

    checked: displaySettings.orientationLock !== "dynamic"
    onToggled: {
        if (checked) {
            displaySettings.orientationLock = "dynamic"
        } else if (__silica_applicationwindow_instance.orientation === Orientation.Portrait) {
            displaySettings.orientationLock = "portrait"
        } else if (__silica_applicationwindow_instance.orientation === Orientation.PortraitInverted) {
            displaySettings.orientationLock = "portrait-inverted"
        } else if (__silica_applicationwindow_instance.orientation === Orientation.Landscape) {
            displaySettings.orientationLock = "landscape"
        } else if (__silica_applicationwindow_instance.orientation === Orientation.LandscapeInverted) {
            displaySettings.orientationLock = "landscape-inverted"
        }
    }

    DisplaySettings { id: displaySettings }
}
