import QtQuick 2.0
import org.nemomobile.systemsettings 1.0

Item {
    id: root

    function setDeveloperMode(value) {
        console.log("DummyDeveloperModeSettings::setDeveloperMode() called")
        workProgress = 0
        timer.install = value
        timer.steps = 0
        workStatus = DeveloperModeSettings.Preparing
        timer.restart()
    }
    function refresh() {
        console.log("DummyDeveloperModeSettings::refresh() called")
    }

    property bool developerModeEnabled
    property string username: "dummy"
    property string developerModeAccountProvider: "jolla"

    property int workProgress
    property int workStatus: DeveloperModeSettings.Idle

    property string wlanIpAddress: "0.0.0.0"
    property string usbIpAddress: "0.0.0.0"

    onDeveloperModeEnabledChanged: console.log("DummyDeveloperModeSettings::developerModeEnabled changed to", developerModeEnabled)
    onWorkStatusChanged: console.log("DummyDeveloperModeSettings::workStatus changed to", workStatus)

    Timer {
        id: timer

        property bool install
        property int steps

        interval: 100
        repeat: true

        onTriggered: {
            workProgress += 2
            if (workProgress >= 100) {
                stop()
                root.developerModeEnabled = install
                root.workStatus = DeveloperModeSettings.Idle
            } else {
                root.workStatus = install ? DeveloperModeSettings.InstallingPackages : DeveloperModeSettings.RemovingPackages
            }
        }
    }
}
