/****************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

pragma Singleton
import QtQml 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0
import Sailfish.Telephony 1.0
import Nemo.DBus 2.0
import Nemo.FileManager 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.devicelock 1.0
import com.jolla.lipstick 0.1

QtObject {
    property Page instance

    // SUW loads on boot, so if it has not finished, then it should be running
    property bool startupWizardRunning: startupWizardDoneWatcher.fileName !== ""

    // Expose device lock state that is exposed to system bus. Mce listens this same
    // and tk_lock is also in system bus. In order to sync tk_lock
    // and device lock state between mce, device lock daemon,
    // and lipstick all information must come through dbus daemon (see JB#39577).
    property int deviceLockState: DeviceLock.Undefined

    property bool eventsViewVisible

    property var simManager: SimManager {
        controlType: SimManagerType.Voice
    }

    // DSSS: Single active card
    // DSDS: Dual-standby
    // DADA: Dual-active
    // The SIM the user has chosen to use. Only needed by DSSS, or phase 2 implementation
    readonly property int activeSim: simManager.activeSim + 1
    // Do we want to show two separate indicators, i.e. we have DSDS or DSDA
    readonly property bool showDualSim: Telephony.multiSimSupported && simManager.ready && simManager.enabledModems.length > 1

    // Voice sim can toggled when more than one sim cards are inserted or as exception one sim card
    // inserted but it's not the active one.
    readonly property bool showMultiSimSelector: Telephony.multiSimSupported && simManager.ready
                                                 && ((Telephony.voiceSimUsageMode === Telephony.ActiveSim && simManager.simCount > 1)
                                                     || (simManager.simCount === 1 && simManager.activeSim === -1))

    property QtObject settings: ConfigurationGroup {
        path: "/desktop/lipstick-jolla-home"

        property bool left_peek_to_events: false
        property int dialog_orientation
        property bool lock_screen_camera: true
        property int security_code_notification_id
        property int blur_iterations: 2
        property int blur_kernel: Kernel.SampleSize17
        property real blur_deviation: 5
        property bool live_snapshots
        property bool lock_screen_events: false
        property bool lock_screen_events_allowed: true
    }

    property var startupWizardDoneWatcher: FileWatcher {
        Component.onCompleted: {
            var markerFile = StandardPaths.home + "/.jolla-startupwizard-usersession-done"
            if (!testFileExists(markerFile)) {
                fileName = markerFile
            }
        }
        onExistsChanged: if (exists) fileName = ""
    }

    function cellularContext(sim) {
        return sim === 2 ? "Cellular_1" : "Cellular"
    }

    property QtObject deviceLock: DBusInterface {
        function getDeviceLockState() {
            if (status === DBusInterface.Available) {
                call("state", [], function(state) {
                    deviceLockState = state
                })
            } else {
                deviceLockState = DeviceLock.Undefined
            }
        }

        function stateChanged(state) {
            deviceLockState = state
        }

        watchServiceStatus: true
        bus: DBus.SystemBus
        service: 'org.nemomobile.devicelock'
        path: '/devicelock'
        iface: 'org.nemomobile.lipstick.devicelock'
        signalsEnabled: true

        onStatusChanged: getDeviceLockState()
        Component.onCompleted: getDeviceLockState()
    }

    property QtObject pendingWindowPrompt: ConfigurationValue {
        key: "/desktop/lipstick-jolla-home/windowprompt/pending"
        defaultValue: []
    }

    property bool windowPromptPending: pendingWindowPrompt.value.length > 0

    property bool weatherAvailable
    function refreshWeatherAvailable() {
        weatherAvailable = fileUtils.exists(StandardPaths.resolveImport("Sailfish.Weather.WeatherIndicator"))
    }

    property FileUtils fileUtils: FileUtils { }

    property TimedStatus timedStatus: TimedStatus {}

    signal showVolumeBar()

    Component.onCompleted: {
        refreshWeatherAvailable()
    }
}
