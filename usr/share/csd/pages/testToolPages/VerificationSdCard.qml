/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
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
        spacing: Theme.paddingLarge
        CsdPageHeader {
            //% "SD card"
            title: qsTrId("csd-he-sd_card")
        }

        DescriptionItem {
            id: guideText
            //% "1. Make sure device has SD card inserted.<br>2. Press 'Start' to test card detection and read and write operations."
            text: qsTrId("csd-la-verification_sd_card_description")
        }

        Label {
            x: Theme.paddingLarge
            width: page.width - (2 * Theme.paddingLarge)

            wrapMode: Text.Wrap

            text: {
                switch (sdcardtest.status) {
                case SdCardTest.NoCard:
                    //% "No card inserted"
                    return qsTrId("csd-la-no_sdcard_inserted")
                case SdCardTest.Unmounted:
                    return sdcardtest.mountFailed
                            //% "SD card could not be mounted"
                            ? qsTrId("csd-la-no_sdcard_mount_failed")
                            //% "SD card unmounted"
                            : qsTrId("csd-la-no_sdcard_umounted")
                case SdCardTest.Mounting:
                    //% "Mounting SD card"
                    return qsTrId("csd-la-sdcard_mounting")
                case SdCardTest.Mounted:
                    //% "SD card mounted"
                    return qsTrId("csd-la-sdcard_mounted")
                case SdCardTest.Unmounting:
                    //% "Unmounting SD card"
                    return qsTrId("csd-la-sdcard_unmounting")
                default:
                    return ""
                }
            }
        }

        Text {
            id: result
            x: Theme.paddingLarge
            font.pixelSize: Theme.fontSizeLarge
            visible: false
        }
    }

    BottomButton {
        id: startButton
        //% "Start"
        text: qsTrId("csd-la-start")
        onClicked: {
            startButton.visible = false
            switch (sdcardtest.sdCardIOTest()) {
            case 0:
                //% "No SD card detected."
                guideText.text = qsTrId("csd-la-no_sdcard_detected")
                //% "Fail"
                result.text = qsTrId("csd-la-fail")
                result.color = "red"
                setTestResult(false)
                break
            case 1:
                //% "Writing data to SD card failed."
                guideText.text = qsTrId("csd-la-writing_data_to_sd_card_failed")
                //% "Fail"
                result.text = qsTrId("csd-la-fail")
                result.color = "red"
                setTestResult(false)
                break
            case 2:
                //% "Reading data from SD card failed."
                guideText.text = qsTrId("csd-la-reading_data_from_sd_card_failed")
                //% "Fail"
                result.text = qsTrId("csd-la-fail")
                result.color = "red"
                setTestResult(false)
                break
            case 3:
                //% "Reading from and writing to SD card succeeded."
                guideText.text = qsTrId("csd-la-reading_and_writing_sd_card_succeeded")
                //% "Pass"
                result.text = qsTrId("csd-la-pass")
                result.color = "green"
                setTestResult(true)
                break
            }
            //% "Result"
            guideText.title = qsTrId("csd-he-result")
            guideText.visible = true
            result.visible = true
            testCompleted(false)
        }
    }

    SdCardTest {
        id: sdcardtest
    }
}
