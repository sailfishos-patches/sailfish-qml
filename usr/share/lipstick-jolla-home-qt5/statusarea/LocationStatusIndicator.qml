/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1

Image {
    property bool recentlyOnDisplay

    source: "image://theme/icon-status-gps" + iconSuffix

    LocationStatus {
        id: locationStatus

        property bool acquiringFix: state === LocationStatus.Acquiring ||
                                    state === LocationStatus.PartialFix
    }

    Binding on opacity {
        when: !blinkAnimation.running
        value: locationStatus.connected ? 1.0 : 0.0
    }

    Behavior on opacity {
        enabled: !locationStatus.acquiringFix && recentlyOnDisplay
        FadeAnimation {}
    }

    SequentialAnimation on opacity {
        id: blinkAnimation

        running: locationStatus.acquiringFix && recentlyOnDisplay
        loops: Animation.Infinite
        PropertyAnimation { to: Theme.opacityLow; duration: 500 }
        PropertyAnimation { to: 0.01; duration: 500 }
    }
}
