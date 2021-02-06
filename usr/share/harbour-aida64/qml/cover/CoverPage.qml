import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.aida64.infopageloader 1.0

CoverBackground {
    id: cover

    property int currPage
    property int cpuCount:  infopageloader.getCoverCPUCount()

    property int cpuClkLines: if (cpuCount > 8) return 6
                              else
                              if (cpuCount > 6) return 5
                              else              return cpuCount

    property int tempCount: infopageloader.getCoverTempCount()
    property int temp1Idx:  infopageloader.getCoverTempIdx(0)
    property int temp2Idx:  infopageloader.getCoverTempIdx(1)
    property int temp3Idx:  infopageloader.getCoverTempIdx(2)
    property int temp4Idx:  infopageloader.getCoverTempIdx(3)
    property int temp5Idx:  infopageloader.getCoverTempIdx(4)
    property int temp6Idx:  infopageloader.getCoverTempIdx(5)
    property int temp7Idx:  infopageloader.getCoverTempIdx(6)
    property int temp8Idx:  infopageloader.getCoverTempIdx(7)
    property string battLevel
    property string battStatus
    property string battTemp
    property string battVolt
    property string battChgRate
    property string cpuLoad
    property string cpuClkCore1
    property string cpuClkCore2
    property string cpuClkCore3
    property string cpuClkCore4
    property string cpuClkCore5
    property string cpuClkCore6
    property string cpuClkCore7
    property string cpuClkCore8
    property string cpuClkCore9
    property string cpuClkCore10
    property string temp1
    property string temp2
    property string temp3
    property string temp4
    property string temp5
    property string temp6
    property string temp7
    property string temp8
    property string freeMem
    property string gpuLoad
    property string gpuClk

    property int battLines: if (battChgRate != "") return 5
                            else                   return 4

    property int memLines: if (gpuLoad != "" && gpuClk != "") return 5
                           else
                           if (gpuLoad != "" || gpuClk != "") return 4
                           else                               return 2

    property int cpuPageAvailHeight: cover.height - Theme.paddingMedium * 3 - labelExtraSmall.height - labelMedium.height - labelSmall.height - Theme.paddingSmall * 2 - Theme.iconSizeSmall
    property int tempPageAvailHeight: cover.height - Theme.paddingMedium * 3 - labelExtraSmall.height - labelMedium.height - Theme.paddingSmall - Theme.iconSizeSmall
    property int battPageAvailHeight: tempPageAvailHeight
    property int memPageAvailHeight: tempPageAvailHeight

    property int cpuClkFontSize:
        if (cpuClkLines * (labelExtraSmall.height + Theme.paddingSmall) > cpuPageAvailHeight) return Theme.fontSizeTiny
        else
        if (cpuClkLines * (labelSmall.height + Theme.paddingSmall) > cpuPageAvailHeight) return Theme.fontSizeExtraSmall
        else return Theme.fontSizeSmall

    property int tempFontSize:
        if (tempCount * (labelSmall.height + Theme.paddingSmall) > tempPageAvailHeight) return Theme.fontSizeExtraSmall
        else return Theme.fontSizeSmall;

    property int battFontSize:
        if (battLines * (labelExtraSmall.height + Theme.paddingSmall) > battPageAvailHeight) return Theme.fontSizeTiny
        else
        if (battLines * (labelSmall.height + Theme.paddingSmall) > battPageAvailHeight) return Theme.fontSizeExtraSmall
        else return Theme.fontSizeSmall

    property int memFontSize:
        if (memLines * (labelExtraSmall.height + Theme.paddingSmall) > memPageAvailHeight) return Theme.fontSizeTiny
        else
        if (memLines * (labelSmall.height + Theme.paddingSmall) > memPageAvailHeight) return Theme.fontSizeExtraSmall
        else return Theme.fontSizeSmall

    InfoPageLoader {
        id: infopageloader
    }

    function refreshReadings() {
        if (currPage === InfoPageLoader.COVERPAGEENUM_BATTERY) {
            battLevel   = infopageloader.getCoverBatteryLevel();
            battStatus  = infopageloader.getCoverBatteryStatus();
            battTemp    = infopageloader.getCoverBatteryTemp(settings.tempUnit);
            battVolt    = infopageloader.getCoverBatteryVolt();
            battChgRate = infopageloader.getCoverBatteryChargeRate();
        }
        else
        if (currPage === InfoPageLoader.COVERPAGEENUM_CPU) {
            cpuLoad = infopageloader.getCoverCPULoad();
            cpuClkCore1 = infopageloader.getCoverCPUCoreClock(0);
            if (cpuCount > 1) {
                cpuClkCore2 = infopageloader.getCoverCPUCoreClock(1);
                if (cpuCount > 2) {
                    cpuClkCore3 = infopageloader.getCoverCPUCoreClock(2);
                    if (cpuCount > 3) {
                        cpuClkCore4 = infopageloader.getCoverCPUCoreClock(3);
                        if (cpuCount > 4) {
                            cpuClkCore5 = infopageloader.getCoverCPUCoreClock(4);
                            if (cpuCount > 5) {
                                cpuClkCore6 = infopageloader.getCoverCPUCoreClock(5);
                                if (cpuCount > 6) {
                                    cpuClkCore7 = infopageloader.getCoverCPUCoreClock(6);
                                    if (cpuCount > 7) {
                                        cpuClkCore8 = infopageloader.getCoverCPUCoreClock(7);
                                        if (cpuCount > 8) {
                                            cpuClkCore9 = infopageloader.getCoverCPUCoreClock(8);
                                            if (cpuCount > 9) {
                                                cpuClkCore10 = infopageloader.getCoverCPUCoreClock(9);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        else
        if (currPage === InfoPageLoader.COVERPAGEENUM_THERMAL) {
            if (tempCount > 0) {
                temp1 = infopageloader.getCoverTemp(temp1Idx, settings.tempUnit);
                if (tempCount > 1) {
                    temp2 = infopageloader.getCoverTemp(temp2Idx, settings.tempUnit);
                    if (tempCount > 2) {
                        temp3 = infopageloader.getCoverTemp(temp3Idx, settings.tempUnit);
                        if (tempCount > 3) {
                            temp4 = infopageloader.getCoverTemp(temp4Idx, settings.tempUnit);
                            if (tempCount > 4) {
                                temp5 = infopageloader.getCoverTemp(temp5Idx, settings.tempUnit);
                                if (tempCount > 5) {
                                    temp6 = infopageloader.getCoverTemp(temp6Idx, settings.tempUnit);
                                    if (tempCount > 6) {
                                        temp7 = infopageloader.getCoverTemp(temp7Idx, settings.tempUnit);
                                        if (tempCount > 7) {
                                            temp8 = infopageloader.getCoverTemp(temp8Idx, settings.tempUnit);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        else
        if (currPage === InfoPageLoader.COVERPAGEENUM_MEMORY) {
            freeMem = infopageloader.getCoverFreeMem();
            gpuLoad = infopageloader.getCoverGPULoad();
            gpuClk  = infopageloader.getCoverGPUClock();
        }
    }

    Component.onCompleted: {
        currPage = InfoPageLoader.COVERPAGEENUM_BATTERY
        refreshReadings()
    }

    Timer {
        triggeredOnStart: true
        running: cover.status === Cover.Active
        interval: 1000
        repeat: true
        onTriggered: refreshReadings()
    }

    Column {
        x: Theme.paddingMedium
        y: x
        width: parent.width - 2 * x
        spacing: Theme.paddingSmall

        Label {
            id: labelExtraSmall
            font.pixelSize: Theme.fontSizeExtraSmall
            visible: false
        }

        Label {
            id: labelSmall
            font.pixelSize: Theme.fontSizeSmall
            visible: false
        }

        Label {
            id: labelMedium
            font.pixelSize: Theme.fontSizeMedium
            visible: false
        }

        Label {
            id: cpuClkLabel
            font.pixelSize: cpuClkFontSize
            visible: false
        }

        Label {
            id: tempLabel
            font.pixelSize: tempFontSize
            visible: false
        }

        Label {
            text: APP_NAME
            font.pixelSize: Theme.fontSizeExtraSmall
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            text: {
                if (currPage === InfoPageLoader.COVERPAGEENUM_BATTERY) return qsTrId("pagetitle_battery") + lcs.emptyString
                if (currPage === InfoPageLoader.COVERPAGEENUM_THERMAL) return qsTrId("pagetitle_thermal") + lcs.emptyString
                if (currPage === InfoPageLoader.COVERPAGEENUM_MEMORY)  return qsTrId("coverpagetitle_memory") + lcs.emptyString

                if (labelCPULoad.visible) return qsTrId("pagetitle_cpu") + lcs.emptyString
                else                      return qsTrId("pagetitle_cpu") + ": " + cpuLoad + lcs.emptyString
            }
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeMedium
            anchors.horizontalCenter: parent.horizontalCenter
        }

// Battery cover page
//
        Column {
            visible: currPage === InfoPageLoader.COVERPAGEENUM_BATTERY
            width: parent.width
            spacing: Theme.paddingSmall

            Label {
                text: battLevel
//text: "iconSizeSmall = " + Theme.iconSizeSmall
                font.pixelSize: battFontSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: battStatus
//text: "cover.height = " + cover.height
                font.pixelSize: battFontSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: battTemp
//text: "paddingMedium = " + Theme.paddingMedium
                font.pixelSize: battFontSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: battVolt
//text: "paddingSmall = " + Theme.paddingSmall
                font.pixelSize: battFontSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: battChgRate
                font.pixelSize: battFontSize
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

// CPU cover page
//
        Column {
            visible: currPage === InfoPageLoader.COVERPAGEENUM_CPU
            width: parent.width
            spacing: Theme.paddingSmall

            Label {
                id: labelCPULoad
                visible: cpuClkLines * (cpuClkLabel.height + Theme.paddingSmall) <= cpuPageAvailHeight
                text: cpuLoad
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }

// 6 rows for up to 6 CPU cores
//
            Row {
                width: parent.width
                visible: cpuCount < 7

                Label {
                    text: infopageloader.getCoverCPUCoreLabel(0) + lcs.emptyString
                    color: Theme.secondaryColor
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.4
                }

                Label {
                    text: cpuClkCore1
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.6
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount > 1 && cpuCount < 7

                Label {
                    text: infopageloader.getCoverCPUCoreLabel(1) + lcs.emptyString
                    color: Theme.secondaryColor
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.4
                }

                Label {
                    text: cpuClkCore2
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.6
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount > 2 && cpuCount < 7

                Label {
                    text: infopageloader.getCoverCPUCoreLabel(2) + lcs.emptyString
                    color: Theme.secondaryColor
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.4
                }

                Label {
                    text: cpuClkCore3
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.6
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount > 3 && cpuCount < 7

                Label {
                    text: infopageloader.getCoverCPUCoreLabel(3) + lcs.emptyString
                    color: Theme.secondaryColor
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.4
                }

                Label {
                    text: cpuClkCore4
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.6
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount > 4 && cpuCount < 7

                Label {
                    text: infopageloader.getCoverCPUCoreLabel(4) + lcs.emptyString
                    color: Theme.secondaryColor
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.4
                }

                Label {
                    text: cpuClkCore5
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.6
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount > 5 && cpuCount < 7

                Label {
                    text: infopageloader.getCoverCPUCoreLabel(5) + lcs.emptyString
                    color: Theme.secondaryColor
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.4
                }

                Label {
                    text: cpuClkCore6
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.6
                    horizontalAlignment: Text.AlignRight
                }
            }

// 5 rows for 7 or 8 CPU cores
//
            Row {
                width: parent.width
                visible: cpuCount == 7 || cpuCount == 8

                Label {
                    text: "C1..C4"
                    color: Theme.secondaryColor
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }

                Label {
                    text: "C5..C" + cpuCount
                    color: Theme.secondaryColor
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount == 7 || cpuCount == 8

                Label {
                    text: cpuClkCore1
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }

                Label {
                    text: cpuClkCore5
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount == 7 || cpuCount == 8

                Label {
                    text: cpuClkCore2
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }

                Label {
                    text: cpuClkCore6
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount == 7 || cpuCount == 8

                Label {
                    text: cpuClkCore3
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }

                Label {
                    text: cpuClkCore7
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount == 7 || cpuCount == 8

                Label {
                    text: cpuClkCore4
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }

                Label {
                    text: cpuClkCore8
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                    visible: cpuCount > 7
                }
            }

// 6 rows for 9 or 10 CPU cores
//
            Row {
                width: parent.width
                visible: cpuCount > 8

                Label {
                    text: "C1..C5"
                    color: Theme.secondaryColor
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }

                Label {
                    text: "C6..C" + cpuCount
                    color: Theme.secondaryColor
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount > 8

                Label {
                    text: cpuClkCore1
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }

                Label {
                    text: cpuClkCore6
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount > 8

                Label {
                    text: cpuClkCore2
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }

                Label {
                    text: cpuClkCore7
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount > 8

                Label {
                    text: cpuClkCore3
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }

                Label {
                    text: cpuClkCore8
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount > 8

                Label {
                    text: cpuClkCore4
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }

                Label {
                    text: cpuClkCore9
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: cpuCount > 8

                Label {
                    text: cpuClkCore5
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                }

                Label {
                    text: cpuClkCore10
                    font.pixelSize: cpuClkFontSize
                    width: parent.width * 0.5
                    horizontalAlignment: Text.AlignRight
                    visible: cpuCount > 9
                }
            }
        }

// Thermal cover page
//
        Column {
            visible: currPage === InfoPageLoader.COVERPAGEENUM_THERMAL
            width: parent.width
            spacing: Theme.paddingSmall

            Row {
                width: parent.width
                visible: tempCount >= 1

                Label {
                    text: infopageloader.getCoverTempLabel(temp1Idx)
                    clip: true
                    color: Theme.secondaryColor
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.6
                }

                Label {
                    text: temp1
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.4
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: tempCount >= 2

                Label {
                    text: infopageloader.getCoverTempLabel(temp2Idx)
                    clip: true
                    color: Theme.secondaryColor
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.6
                }

                Label {
                    text: temp2
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.4
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: (tempCount >= 3) && (3 * (tempLabel.height + Theme.paddingSmall) <= tempPageAvailHeight)

                Label {
                    text: infopageloader.getCoverTempLabel(temp3Idx)
                    clip: true
                    color: Theme.secondaryColor
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.6
                }

                Label {
                    text: temp3
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.4
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: (tempCount >= 4) && (4 * (tempLabel.height + Theme.paddingSmall) <= tempPageAvailHeight)

                Label {
                    text: infopageloader.getCoverTempLabel(temp4Idx)
                    clip: true
                    color: Theme.secondaryColor
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.6
                }

                Label {
                    text: temp4
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.4
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: (tempCount >= 5) && (5 * (tempLabel.height + Theme.paddingSmall) <= tempPageAvailHeight)
                Label {
                    text: infopageloader.getCoverTempLabel(temp5Idx)
                    clip: true
                    color: Theme.secondaryColor
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.6
                }

                Label {
                    text: temp5
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.4
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: (tempCount >= 6) && (6 * (tempLabel.height + Theme.paddingSmall) <= tempPageAvailHeight)

                Label {
                    text: infopageloader.getCoverTempLabel(temp6Idx)
                    clip: true
                    color: Theme.secondaryColor
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.6
                }

                Label {
                    text: temp6
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.4
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: (tempCount >= 7) && (7 * (tempLabel.height + Theme.paddingSmall) <= tempPageAvailHeight)

                Label {
                    text: infopageloader.getCoverTempLabel(temp7Idx)
                    clip: true
                    color: Theme.secondaryColor
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.6
                }

                Label {
                    text: temp7
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.4
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width
                visible: (tempCount >= 8) && (8 * (tempLabel.height + Theme.paddingSmall) <= tempPageAvailHeight)

                Label {
                    text: infopageloader.getCoverTempLabel(temp8Idx)
                    clip: true
                    color: Theme.secondaryColor
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.6
                }

                Label {
                    text: temp8
                    font.pixelSize: tempFontSize
                    width: parent.width * 0.4
                    horizontalAlignment: Text.AlignRight
                }
            }

            Label {
                text: qsTrId("thermal_page_no_thermal_sensors_found") + lcs.emptyString
                visible: tempCount < 1
                font.pixelSize: Theme.fontSizeSmall
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }

// Memory cover page
//
        Column {
            visible: currPage === InfoPageLoader.COVERPAGEENUM_MEMORY
            width: parent.width
            spacing: Theme.paddingSmall

            Row {
                width: parent.width

                Label {
                    text: qsTrId("coverpage_total") + lcs.emptyString
                    color: Theme.secondaryColor
                    font.pixelSize: memFontSize
                    width: parent.width * 0.3
                }

                Label {
                    text: infopageloader.getCoverTotalMem() + lcs.emptyString
                    font.pixelSize: memFontSize
                    width: parent.width * 0.7
                    horizontalAlignment: Text.AlignRight
                }
            }

            Row {
                width: parent.width

                Label {
                    text: qsTrId("coverpage_free") + lcs.emptyString
                    color: Theme.secondaryColor
                    font.pixelSize: memFontSize
                    width: parent.width * 0.3
                }

                Label {
                    text: freeMem
                    font.pixelSize: memFontSize
                    width: parent.width * 0.7
                    horizontalAlignment: Text.AlignRight
                }
            }

            Label {
                text: qsTrId("coverpagetitle_gpu") + lcs.emptyString
                visible: gpuLoad != "" || gpuClk != ""
                color: Theme.secondaryColor
                font.pixelSize: Theme.fontSizeMedium
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                id: labelGPULoad
                text: gpuLoad
                font.pixelSize: memFontSize
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                id: labelGPUClk
                text: gpuClk
                font.pixelSize: memFontSize
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    CoverActionList {
        id: coverAction

        CoverAction {
            id: coverActionPrev
            iconSource: "image://theme/icon-cover-previous"
            onTriggered : {
                if (currPage === InfoPageLoader.COVERPAGEENUM_BATTERY)
                    currPage = InfoPageLoader.COVERPAGEENUM_MEMORY
                else
                if (currPage === InfoPageLoader.COVERPAGEENUM_MEMORY)
                    currPage = InfoPageLoader.COVERPAGEENUM_THERMAL
                else
                if (currPage === InfoPageLoader.COVERPAGEENUM_THERMAL)
                    currPage = InfoPageLoader.COVERPAGEENUM_CPU
                else
                if (currPage === InfoPageLoader.COVERPAGEENUM_CPU)
                    currPage = InfoPageLoader.COVERPAGEENUM_BATTERY
                refreshReadings();
            }
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
            onTriggered : {
                if (currPage === InfoPageLoader.COVERPAGEENUM_BATTERY)
                    currPage = InfoPageLoader.COVERPAGEENUM_CPU
                else
                if (currPage === InfoPageLoader.COVERPAGEENUM_CPU)
                    currPage = InfoPageLoader.COVERPAGEENUM_THERMAL
                else
                if (currPage === InfoPageLoader.COVERPAGEENUM_THERMAL)
                    currPage = InfoPageLoader.COVERPAGEENUM_MEMORY
                else
                if (currPage === InfoPageLoader.COVERPAGEENUM_MEMORY)
                    currPage = InfoPageLoader.COVERPAGEENUM_BATTERY
                refreshReadings();
            }
        }
    }
}
