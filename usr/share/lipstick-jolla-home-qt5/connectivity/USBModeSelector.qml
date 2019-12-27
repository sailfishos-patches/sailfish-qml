/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import "../systemwindow"

SystemWindow {
    id: usbDialog
    objectName: "usbDialog"
    property bool largeIcons: Screen.sizeCategory >= Screen.Large

    // The mode selection buttons should be enabled only in ask mode.
    // Note that we can leave ask mode also for reasons that have
    // nothing to do with pressing the buttons.
    property bool inAskMode: USBMode.currentMode == USBMode.MODE_ASK

    // Mode selected from this dialog. Once set, do not allow change
    // of direction.
    property string selectedMode

    opacity: shouldBeVisible ? 1 : 0
    contentHeight: content.height
    _windowOpacity: 1.0 // Don't bother animating, once lipstick has decided the dialog should be hidden it is gone.

    onOpacityChanged: {
        if (!shouldBeVisible)
            usbModeAgent.windowVisible = false
    }

    function selectUsbMode(mode, dismiss) {
        if (!selectedMode && inAskMode && shouldBeVisible) {
            selectedMode = mode
            usbModeAgent.setMode(mode)
        }
        if (dismiss && shouldBeVisible) {
            shouldBeVisible = false
        }
    }

    function selectDefaultMode() {
        selectUsbMode(USBMode.MODE_CHARGING, true)
    }

    readonly property var usbModes: [
        {
            //% "Charging Only"
            text: qsTrId("lipstick-jolla-home-bt-charging_only"),
            iconSource: largeIcons ? "image://theme/icon-l-charging"
                                   : "image://theme/icon-m-charging",
            mode: USBMode.MODE_CHARGING
        },{
            //% "Mass Storage Mode"
            text: qsTrId("lipstick-jolla-home-bt-mass_storage_mode"),
            iconSource: largeIcons ? "image://theme/icon-l-storage"
                                   : "image://theme/icon-m-storage",
            mode:  USBMode.MODE_MASS_STORAGE
        },{
            //% "MTP Mode"
            text: qsTrId("lipstick-jolla-home-bt-mtp_mode"),
            iconSource: largeIcons ? "image://theme/icon-l-storage"
                                   : "image://theme/icon-m-storage",
            mode: USBMode.MODE_MTP
        },{
            //% "Tethering"
            text: qsTrId("lipstick-jolla-home-bt-connection_sharing_mode"),
            iconSource: largeIcons ? "image://theme/icon-l-mobile-network"
                                   : "image://theme/icon-m-mobile-network",
            mode: USBMode.MODE_CONNECTION_SHARING
        },{
            //% "Developer Mode"
            text: qsTrId("lipstick-jolla-home-bt-developer_mode"),
            iconSource: largeIcons ? "image://theme/icon-l-developer-mode"
                                   : "image://theme/icon-m-developer-mode",
            mode: USBMode.MODE_DEVELOPER
        },{
            //% "PC Connection"
            text: qsTrId("lipstick-jolla-home-bt-pc_suite_mode"),
            iconSource: largeIcons ? "image://theme/icon-l-computer"
                                   : "image://theme/icon-m-computer",
            mode: USBMode.MODE_PC_SUITE
        },{
            //% "Adb Mode"
            text: qsTrId("lipstick-jolla-home-bt-adb_mode"),
            iconSource: largeIcons ? "image://theme/icon-l-developer-mode"
                                   : "image://theme/icon-m-developer-mode",
            mode: USBMode.MODE_ADB
        },{
            //% "Diagnostic Mode"
            text: qsTrId("lipstick-jolla-home-bt-diag_mode"),
            iconSource: largeIcons ? "image://theme/icon-l-diagnostic"
                                   : "image://theme/icon-m-diagnostic",
            mode: USBMode.MODE_DIAG
        }
    ]

    SystemDialogLayout {
        contentHeight: content.height
        onDismiss: selectDefaultMode()

        Column {
            id: content
            width: parent.width

            SystemDialogHeader {
                id: header

                //% "USB connected"
                title: qsTrId("lipstick-jolla-home-bt-usb_connected")

                //: Displayed above the available USB connection modes
                //% "Switch to one of the following modes(s)"
                description: qsTrId("lipstick-jolla-home-la-usb_connected_description", buttonModel.count)
                topPadding: transpose ? Theme.paddingLarge : 2*Theme.paddingLarge
            }
            Row {
                id: buttonRow

                property real buttonWidth: Math.min(parent.width / buttonModel.count, Theme.itemSizeHuge*1.5)

                anchors.horizontalCenter: parent.horizontalCenter
                height: {
                    var tallest = 0
                    for (var i = 0; i < children.length; ++i) {
                        tallest = Math.max(tallest, children[i].implicitHeight)
                    }
                    return tallest
                }

                Repeater {
                    model: ListModel { id: buttonModel }

                    SystemDialogIconButton {
                        id: button
                        objectName: "button" + model.mode
                        width: buttonRow.buttonWidth
                        height: buttonRow.height
                        text: model.text
                        iconSource: model.iconSource
                        enabled: inAskMode
                        onClicked: selectUsbMode(model.mode, true)
                    }
                }
            }
        }
    }

    Connections {
        target: usbModeAgent
        onWindowVisibleChanged: {
            if (usbModeAgent.windowVisible) {
                usbDialog.selectedMode = ""
                usbDialog.shouldBeVisible = true
            } else {
                usbDialog.selectDefaultMode()
            }
        }
    }

    Connections {
        target: USBMode
        onAvailableModesChanged: createButtons()
    }

    function createButtons()
    {
        buttonModel.clear()

        var chargingFound = false
        var modes = USBMode.availableModes
        for (var i = 0; i < modes.length; i++) {
            var mode = modes[i]
            createButton(i, mode)
            chargingFound |= (mode == USBMode.MODE_CHARGING)
        }

        if (!chargingFound) {
            createButton(buttonModel.count, USBMode.MODE_CHARGING)
        }
    }

    function createButton(index, mode)
    {
        for (var i = 0; i < usbModes.length; i++) {
            var item = usbModes[i]
            if (item.mode == mode) {
                if (item.text) {
                    buttonModel.insert(index, {"mode": mode, "text": item.text, "iconSource": item.iconSource})
                    return
                }
                break
            }
        }

        buttonModel.insert(index, {
            //% "Mode %1"
            "text": qsTrId("lipstick-jolla-home-bt-other_mode").arg(mode),
            "iconSource": largeIcons ? "image://theme/icon-l-usb"
                                     : "image://theme/icon-m-usb",
            "mode": mode})
    }

    Component.onCompleted: createButtons()

    Connections {
        target: Lipstick.compositor
        onDisplayOff: usbDialog.selectDefaultMode()
    }
}
