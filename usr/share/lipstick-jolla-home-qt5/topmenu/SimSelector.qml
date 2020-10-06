/*
 * Copyright (c) 2015 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0 as Telephony
import Sailfish.AccessControl 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

Item {
    id: root

    property real verticalOffset
    property int innerMargin: Theme.paddingLarge * 2

    width: parent.width
    height: simSelector.height
    clip: simSelector.y < 0
    visible: simSelector.active
    Loader {
        id: simSelector
        y: Math.min(0, -height - parent.y + verticalOffset)
        width: parent.width
        active: Desktop.showMultiSimSelector
        sourceComponent: Telephony.SimSelector {
            enabled: !Lipstick.compositor.topMenuLayer.housekeeping
                     && AccessControl.hasGroup(AccessControl.RealUid, "sailfish-system")
            opacity: enabled ? 1.0 : Theme.opacityLow
            innerMargin: root.innerMargin
        }
    }
}
