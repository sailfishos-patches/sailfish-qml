/****************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.0
import MeeGo.QOfono 0.2
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1

Row {
    id: cellularNetworkTypeStatusIndicator
    property alias text: cellularNetworkTypeStatusIndicatorText.text
    property alias color: cellularNetworkTypeStatusIndicatorText.color

    readonly property int dataSimIndex: Desktop.simManager.indexOfModem(Desktop.simManager.defaultDataModem)

    // for testing
    property bool _cellularGPRSAttached: ofonoConnectionManager.attachedValue
    property string _cellularRegistrationStatus: ofonoNetworkRegistration.statusValue
    property string _cellularDataTechnology: ofonoNetworkRegistration.technologyValue

    visible: dataSimIndex >= 0 && width > 0
    spacing: Math.round(Theme.paddingSmall/6)

    OfonoNetworkRegistration {
        id: ofonoNetworkRegistration
        modemPath: Desktop.simManager.defaultDataModem
        readonly property string statusValue: valid ? status : "invalid"
        readonly property string technologyValue: valid ? technology : "invalid"
    }

    OfonoConnMan {
        id: ofonoConnectionManager
        modemPath: Desktop.simManager.defaultDataModem
        readonly property bool attachedValue: valid && attached
    }

    Text {
        id: cellularNetworkTypeStatusIndicatorText
        font {
            family: Theme.fontFamilyHeading
            pixelSize: Theme.fontSizeSmall
        }
        horizontalAlignment: Text.AlignRight
        color: Theme.primaryColor
        text: {
            var techToG = {gsm: "2", edge: "2.5", umts: "3", hspa: "3.5", lte: "4"}
            var onlineIds = {registered: true, roaming: true}

            return (fakeOperator === ""
                    ? ((_cellularGPRSAttached && onlineIds[_cellularRegistrationStatus])
                       ? (techToG[_cellularDataTechnology] || "")
                       : "")
                    : "3.5");
        }
    }

    Text {
        id: cellularNetworkTypeStatusIndicatorGeneration
        anchors {
            baseline: cellularNetworkTypeStatusIndicatorText.baseline
        }
        font {
            family: Theme.fontFamily
            pixelSize: Theme.fontSizeSmall
        }
        horizontalAlignment: Text.AlignRight
        color: cellularNetworkTypeStatusIndicatorText.color
        text: cellularNetworkTypeStatusIndicatorText.text.length > 0 ? "G" : ""
    }
}
