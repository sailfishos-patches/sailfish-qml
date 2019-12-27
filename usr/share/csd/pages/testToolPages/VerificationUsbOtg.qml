/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    Column {
        width: page.width

        CsdPageHeader {
            //% "USB OTG"
            title: qsTrId("csd-he-usb-otg")
        }

        DescriptionItem {
            x: Theme.paddingLarge
            //% "1. Detach all usb cables from the device.<br>2. Attach mass storage with USB OTG cable to the USB port."
            text: qsTrId("csd-la-usbotg_instructions")
        }

        Row {
            x: Theme.paddingLarge
            width: parent.width - Theme.paddingLarge * 2
            spacing: Theme.paddingMedium

            Label {
                id: usbotgStateLabel
                //% "USB OTG State:"
                text: qsTrId("csd-la-usb_otg_state")
            }

            Label {
                width: parent.width - usbotgStateLabel.width - parent.spacing
                wrapMode: Text.Wrap
                text: {
                    if (!usbotg.massStorage) {
                        //% "Mass Storage is not attached"
                        return qsTrId("csd-la-storage_not_attached")
                    } else {
                        //% "Mass Storage attached"
                        return qsTrId("csd-la-storage_attached")
                    }
                }
            }
        }

        Label {
            x: Theme.paddingLarge
            color: "green"
            visible: usbotg.massStorage
            //% "Pass"
            text: qsTrId("csd-la-pass")
        }
    }

    // After finding mass storage device automatically finalize the test.
    Timer {
        interval: 2000
        running: usbotg.massStorage
        repeat: false
        onTriggered: {
           setTestResult(true)
           testCompleted(true)
        }
    }

    FailBottomButton {
        visible: !usbotg.massStorage
        onClicked: {
            setTestResult(false)
            testCompleted(true)
        }
    }

    UsbOtg {
        id: usbotg
    }
}
