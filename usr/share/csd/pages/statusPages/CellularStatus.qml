/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import MeeGo.Connman 0.2
import org.freedesktop.contextkit 1.0


Column {
    property string modemContext

    Row {
        spacing: Theme.paddingMedium
        CheckLabel {
            checked: cellularStatus.value !== "disabled"
            //% "Enabled"
            text: qsTrId("csd-la-enabled")
        }
        CheckLabel {
            checked: !!cellularDataContextProperty.value
            //% "Data"
            text: qsTrId("csd-la-data")
        }
        Label { text: "Reg: %1".arg(cellularStatus.value) }
        Row {
            Label {
                text: {
                    var val = cellularDataTechnologyContextProperty.value
                    if (val !== undefined && val !== 'unknown') {
                        var techToG = {gprs: "2", egprs: "2.5", umts: "3", hspa: "3.5", lte: "4"}
                        return techToG[val] + "G"
                    }
                    return ""
                }
            }
            Image {
                anchors.verticalCenter: parent.verticalCenter
                source: {
                    var path = function(name) {
                        return "image://theme/icon-status-" + name
                    }

                    switch (cellularStatus.value) {
                    case "no-sim":
                        return path("no-sim")
                    case "offline":
                        return path("no-cellular")
                    case "home":
                    case "roam":
                        var bars = cellularSignalBarsContextProperty.value
                        bars = (bars === undefined ? "0" : bars)
                        return path(("cellular-") + bars)
                    default:
                        return ""
                    }
                }
            }
            Item { width: Theme.paddingSmall; height: 1 }
            Label { text: cellularSignalStrengthContextProperty.value || "" }
        }
    }

    ContextProperty {
        id: cellularStatus
        key: modemContext + ".RegistrationStatus"
    }
    ContextProperty {
        id: cellularSignalBarsContextProperty
        key: modemContext + ".SignalBars"
    }
    ContextProperty {
        id: cellularSignalStrengthContextProperty
        key: modemContext + ".SignalStrength"
    }
    ContextProperty {
        id: cellularDataTechnologyContextProperty
        key: modemContext + ".DataTechnology"
    }
    ContextProperty {
        id: cellularDataContextProperty
        key: modemContext + ".GPRSAttached"
    }
}
