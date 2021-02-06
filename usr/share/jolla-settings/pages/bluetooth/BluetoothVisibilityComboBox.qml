import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

ComboBox {
    id: root

    signal discoverableSettingChanged(int timeout)

    property bool _discoverable
    property int _discoverableTimeout: -1
    property int _pendingDiscoverableTimeout: -1
    property int _visibilitySecondsExpiry

    // check Qt.application.active to ensure the timer is corrected when app awakes from sleep
    property bool _active: enabled && Qt.application.active

    function loadVisibility(discoverable, discoverableTimeout) {
        _discoverable = discoverable
        _discoverableTimeout = discoverableTimeout
        _visibilitySecondsExpiry = 0
        if (_pendingDiscoverableTimeout >= 0) {
            _setVisibility(_pendingDiscoverableTimeout)
            _pendingDiscoverableTimeout = -1
            return
        }
        if (discoverable) {
            if (discoverableTimeout > 0) {
                _startVisibilityTimer(discoverableTimeout)
            }
            currentIndex = 3    // "On"
        } else {
            currentIndex = 0    // "Off"
        }
    }

    function _startVisibilityTimer(timeoutSeconds) {
        var startTimeMs = discoverableStartTimeConf.value * 1000
        if (startTimeMs != undefined && startTimeMs > 0) {
            var expireTimeMs = startTimeMs + (timeoutSeconds * 1000)
            var waitTimeMs = expireTimeMs - _currentTimeMilliseconds()
            if (waitTimeMs > 0) {
                _visibilitySecondsExpiry = waitTimeMs / 1000
                visibilityTimer.restart()
            }
        }
    }

    function _setVisibility(timeoutSeconds) {
        if (timeoutSeconds < 0) {
            discoverableStartTimeConf.value = -1
            discoverableStartTimeConf.sync()
            discoverableSettingChanged(-1)
        } else {
            // store in seconds, else there are problems when reading the value back from gconf
            discoverableStartTimeConf.value = Math.round(_currentTimeMilliseconds() / 1000)
            discoverableStartTimeConf.sync()
            if (timeoutSeconds > 0 && timeoutSeconds == _discoverableTimeout) {
                // If the currently selected timeout is re-selected (i.e. the timeout should be
                // reset from the current time), set the timeout to some other value (e.g. 0)
                // before setting it to the the selected timeout, else BlueZ will not recognize
                // the timeout re-set.
                _pendingDiscoverableTimeout = timeoutSeconds
                timeoutSeconds = 0
            }
            discoverableSettingChanged(timeoutSeconds)
        }
    }

    function _currentTimeMilliseconds() {
        return (new Date()).valueOf()
    }

    on_ActiveChanged: {
        if (_active) {
            if (_discoverableTimeout > 0) {
                root._startVisibilityTimer(_discoverableTimeout)
            }
        } else {
            visibilityTimer.stop()
        }
    }

    ConfigurationValue {
        id: discoverableStartTimeConf
        key: "/desktop/jolla/bluetooth/discoverable_start_time"
    }

    Timer {
        id: visibilityTimer
        interval: 1000
        repeat: true
        onTriggered: {
            // don't put timer below 1 second, because it looks odd to see '00:00' in the countdown
            // (i.e. in the second or so when we are waiting for bluez to update the 'discoverable' state)
            if (_visibilitySecondsExpiry <= 1) {
                stop()
            } else {
                root._visibilitySecondsExpiry -= 1
            }
        }
    }

    //: Whether this bluetooth device is visible to other bluetooth devices
    //% "Visibility"
    label: qsTrId("settings_bluetooth-la-device-visibility")

    value: !_discoverable
           ? offMenuitem.text
           : _visibilitySecondsExpiry > 0
               //: Indicates the bluetooth device is visible, with %1 = time remaining. E.g. "On (0:29)" if in 29 seconds the visibility will change from "on" to "off".
               //% "On (%1)"
             ? qsTrId("settings_bluetooth-va-visibility_on_with_time").arg(Format.formatDuration(_visibilitySecondsExpiry, Formatter.DurationShort))
             : onMenuItem.text

    menu: ContextMenu {
        MenuItem {
            id: offMenuitem
            //: Turn off the bluetooth device visibility
            //% "Off"
            text: qsTrId("settings_bluetooth-va-visibility_off")
            onClicked: {
                root._setVisibility(-1)
            }
        }
        MenuItem {
            //: Turn on the bluetooth device visibility for 3 minutes
            //% "On for 3 minutes"
            text: qsTrId("settings_bluetooth-va-for_3_minutes")
            onClicked: {
                root._setVisibility(60 * 3)
            }
        }
        MenuItem {
            //: Turn on the bluetooth device visibility for 15 minutes
            //% "On for 15 minutes"
            text: qsTrId("settings_bluetooth-va-for_15_minutes")
            onClicked: {
                root._setVisibility(60 * 15)
            }
        }
        MenuItem {
            id: onMenuItem
            //: Turn on the bluetooth device visibility
            //% "On"
            text: qsTrId("settings_bluetooth-va-visibility_on")
            onClicked: {
                root._setVisibility(0)
            }
        }
    }
}
