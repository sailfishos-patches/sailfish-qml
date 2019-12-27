/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Martin Jones <martin.jones@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0 as Telephony
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
            innerMargin: root.innerMargin
        }
    }
}
