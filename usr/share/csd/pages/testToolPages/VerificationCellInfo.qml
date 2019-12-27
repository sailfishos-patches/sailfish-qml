/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.ofono 1.0

AllModemsPage {
    id: page

    property int cellCount
    property bool supported

    function updateCellCount() {
        var count = 0
        for (var i = 0; i<availableModems.length; i++) {
            var item = modemList.itemAt(i)
            if (item) {
                count += item.cellCount
            }
        }
        cellCount = count
    }

    onAvailableModemsChanged: updateCellCount()

    Timer {
        id: startTimer
        interval: 2000
        running: true
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        VerticalScrollDecorator {}

        Column {
            id: content
            width: page.width
            spacing: Theme.paddingLarge

            CsdPageHeader {
                //% "Cell positioning"
                title: qsTrId("csd-he-cell_positioning")
            }

            Item {
                id: resultsItem
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: resultLabel.implicitHeight
                property bool busy: failTimerRunning && (startTimer.running || !supported)

                BusyIndicator {
                    anchors.verticalCenter: parent.verticalCenter
                    size: BusyIndicatorSize.Small
                    running: resultsItem.busy
                }

                Label {
                    id: resultLabel
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: resultsItem.busy ? 0 : 1
                    Behavior on opacity { FadeAnimation {}}
                    text: supported ?
                        //% "%n cell(s) found"
                        qsTrId("csd-la-cells_found", cellCount) :
                        //% "Cell positioning is unavailable"
                        qsTrId("csd-la-cell_positioning_unavailable")
                }
            }

            Repeater {
                id: modemList
                model: availableModems
                delegate: modemDelegate
            }
        }
    }

    Component {
        id: modemDelegate

        Column {
            x: Theme.horizontalPageMargin
            width: parent.width - x*2
            spacing: Theme.paddingLarge
            readonly property int cellCount: cellInfo.valid ? cellInfo.cells.length : 0

            onCellCountChanged: updateCellCount()

            OfonoExtCellInfo {
                id: cellInfo
                modemPath: modelData
                onValidChanged: if (valid) page.supported = true
            }

            SectionHeader {
                x: 0
                width: parent.width
                visible: availableModems.length > 1
                //% "SIM: %1"
                text: qsTrId("csd-la-sim-number").arg(index+1)
            }

            Repeater {
                id: cellList
                model: cellInfo.valid ? cellInfo.cells : []
                delegate: cellDelegate
            }
        }
    }

    Component {
        id: cellDelegate

        Column {
            width: parent ? parent.width : 0
            readonly property int offset: Theme.horizontalPageMargin
            readonly property bool gsm: cell.valid && (cell.type == OfonoExtCell.GSM)
            readonly property bool lte: cell.valid && (cell.type == OfonoExtCell.LTE)
            readonly property bool wcdma: cell.valid && (cell.type == OfonoExtCell.WCDMA)

            OfonoExtCell {
                id: cell
                path: modelData
            }

            Row {
                spacing: Theme.paddingSmall
                visible: cell.valid
                width: parent.width
                Label {
                    id: type
                    anchors.verticalCenter: parent.verticalCenter
                    font.bold: true
                    text: (cell.type == OfonoExtCell.GSM) ? "GSM" :
                          (cell.type == OfonoExtCell.LTE) ? "LTE" :
                          (cell.type == OfonoExtCell.WCDMA) ? "WCDMA" : cell.type
                }
                Image {
                    readonly property int bars: cell.signalStrength / 6
                    anchors.bottom: type.baseline
                    id: mask
                    height: type.font.pixelSize
                    visible: (cell.valid && cell.registered)
                    source: "image://theme/icon-status-cellular-" + Math.min(bars,5)
                }
            }

            Label {
                x: offset
                width: parent.width - x
                visible: cell.valid && cell.mcc >= 0
                text: "mcc: " + cell.mcc
            }

            Label {
                x: offset
                width: parent.width - x
                visible: cell.valid && cell.mnc >= 0
                text: "mnc: " + cell.mnc
            }

            Label {
                x: offset
                width: parent.width - x
                visible: (gsm || wcdma) && cell.lac >= 0
                text: "lac: " + cell.lac
            }

            Label {
                x: offset
                width: parent.width - x
                visible: (gsm || wcdma) && cell.cid >= 0
                text: "cid: " + cell.cid
            }

            Label {
                x: offset
                width: parent.width - x
                visible: wcdma && cell.psc >= 0
                text: "psc: " + cell.psc
            }

            Label {
                x: offset
                width: parent.width - x
                visible: lte && cell.ci >= 0
                text: "ci: " + cell.ci
            }

            Label {
                x: offset
                width: parent.width - x
                visible: lte && cell.pci >= 0
                text: "pci: " + cell.pci
            }

            Label {
                x: offset
                width: parent.width - x
                visible: lte && cell.tac >= 0
                text: "tac: " + cell.tac
            }

            Label {
                x: offset
                width: parent.width - x
                visible: cell.valid && cell.signalStrength >= 0
                text: "signalStrength: " + cell.signalStrength
            }

            Label {
                x: offset
                width: parent.width - x
                visible: lte && cell.rsrp >= 0
                text: "rsrp: " + cell.rsrp
            }

            Label {
                x: offset
                width: parent.width - x
                visible: lte && cell.rsrq >= 0
                text: "rsrq: " + cell.rsrq
            }

            Label {
                x: offset
                width: parent.width - x
                visible: lte && cell.rssnr >= 0
                text: "rssnr: " + cell.rssnr
            }

            Label {
                x: offset
                width: parent.width - x
                visible: lte && cell.cqi >= 0
                text: "cqi " + cell.cqi
            }

            Label {
                x: offset
                width: parent.width - x
                visible: lte && cell.timingAdvance >= 0
                text: "timingAdvance: " + cell.timingAdvance
            }

            Label {
                x: offset
                width: parent.width - x
                visible: (gsm || wcdma) && cell.bitErrorRate >= 0
                text: "bitErrorRate: " + cell.bitErrorRate
            }
        }
    }
}
