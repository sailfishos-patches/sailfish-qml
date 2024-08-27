import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.lipstick 0.1

SettingsToggle {
    id: root

    //% "Screenshot"
    name: qsTrId("settings_system-screenshot-button")
    icon.source: "image://theme/icon-m-browser-camera"
    checked: Lipstick.compositor.floatingScreenshotButtonActive

    onToggled: Lipstick.compositor.floatingScreenshotButtonActive = !Lipstick.compositor.floatingScreenshotButtonActive
}
