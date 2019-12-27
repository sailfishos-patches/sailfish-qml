/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Martin Jones <martin.jones@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

Item {
    id: cellularStatusItem
    property int modem: 1
    property string modemContext: Desktop.cellularContext(modem)

    readonly property bool highlight: Telephony.promptForVoiceSim || (Desktop.showDualSim && Desktop.activeSim !== modem)

    // Pressable coloring doesn't make sense here rather active modem should get emphasized (more prominent).
    readonly property string iconSuffix: highlight ? ('?' + Theme.highlightColor) : statusArea.iconSuffix
    readonly property color color: highlight ? Theme.highlightColor : statusArea.color

    height: Theme.iconSizeExtraSmall
    width: cellularSignalStrengthStatusIndicator.width * opacity

    Loader {
        active: !Desktop.showDualSim
        anchors {
            bottom: cellularSignalStrengthStatusIndicator.bottom
            left: cellularSignalStrengthStatusIndicator.left
        }
        sourceComponent: CellularRoamingStatusIndicator {
            id: cellularRoamingStatusIndicator
            modemContext: cellularStatusItem.modemContext
            updatesEnabled: statusArea.recentlyOnDisplay
        }
    }

    CellularSignalStrengthStatusIndicator {
        id: cellularSignalStrengthStatusIndicator
        modem: cellularStatusItem.modem
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        updatesEnabled: statusArea.recentlyOnDisplay
    }
}
