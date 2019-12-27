import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import org.nemomobile.systemsettings 1.0
import com.jolla.lipstick 0.1

SettingsToggle {
    id: root

    //% "Silent"
    name: qsTrId("settings_sound-la-silent")
    icon.source: "image://theme/icon-m-silent"
    checked: profileControl.profile == "silent" || profileControl.profile.ringerVolume == 0

    onToggled: {
        profileControl.toggleSilent()
    }

    ProfileControl {
        id: profileControl

        function toggleSilent() {
            if (root.checked) {
                if (profile == "silent") {
                    Desktop.showVolumeBar()
                    profile = "general"
                }
                if (ringerVolume == 0) {
                    ringerVolume = 60
                }
            } else {
                profile = "silent"
            }
        }
    }

}
