import QtQuick 2.0
import Sailfish.Silica.private 1.0
import org.nemomobile.configuration 1.0

ConfigurationValue {
    // 0 - No hint showing
    // 1 - Swipe home hint showing
    // 2 - Swipe to close hint showing
    // > - Apps can show their hints
    id: coordinationState
    key: "/desktop/sailfish/hints/coordination_state"
    defaultValue: 3 // only show for new users

    property bool exposed
    property Item window
    readonly property bool _active: value < 4

    onExposedChanged: {
        if (!_active)
            return

        if (exposed && Config.demoMode !== Config.Demo) {
            if (_hintConfigs.return_to_home_hint_count < 2) {
                // Swipe home hint
                value = 1
                _hintConfigs.return_to_home_hint_count = _hintConfigs.return_to_home_hint_count + 1
                _hintConfigs.coordination_date = getEpoch() // delay close hint
            } else if (_hintConfigs.close_app_hint_count < 2) {
                if (getEpoch() - _hintConfigs.coordination_date > 2 * 24 * 60 * 60) { // 2 days
                    // Swipe to close hint
                    _hintConfigs.close_app_hint_count = _hintConfigs.close_app_hint_count + 1
                    value = 2
                } else {
                    // App hint
                    value = 3
                }
            } else {
                // App hint, and detach the system hints
                value = 4
            }
        } else {
            // No hints (window is hidden or demo mode)
            value = 0
        }
        _hintConfigs.sync()

        // Show next hint only when a new window opens
        if (!exposed && window) window.closeHinted = true
    }

    function getEpoch() {
        var date = new Date();
        return Math.floor(date.getTime() / 1000)
    }

    readonly property ConfigurationGroup _hintConfigs: ConfigurationGroup {
        path: _active ? "/desktop/sailfish/hints" : ""

        property int return_to_home_hint_count
        property int close_app_hint_count
        property int coordination_date
    }
}
