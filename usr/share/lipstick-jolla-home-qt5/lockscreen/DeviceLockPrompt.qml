/****************************************************************************
**
** Copyright (C) 2014 Jolla Ltd.
** Contact: Joona Petrell <joona.petrell@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.devicelock 1.0
import org.nemomobile.lipstick 0.1

Loader {
    function reset() {
        if (item) {
            item.emergency = false
            item._resetView()
        }
    }
    function loadKeypad() {
        if (source == "" && !lockingDisabled) {
            source = "DeviceLockView.qml"
            lockingDisabled = false // override binding
        }
    }

    // Locked or Undefined == Locked
    readonly property bool locked: Desktop.deviceLockState >= DeviceLock.Locked
    property bool areaVisible: true
    property real headingVerticalOffset
    property bool lockingDisabled: !DeviceLock.enabled

    readonly property bool ready: Desktop.deviceLockState == DeviceLock.Unlocked
                || (item && item.authenticationInput.status !== AuthenticationInput.Idle)

    enabled: locked

    Component.onCompleted: loadKeypad()
    onLockingDisabledChanged: loadKeypad()

    Binding {
        target: item
        property: "headingVerticalOffset"
        value: headingVerticalOffset
    }
}
