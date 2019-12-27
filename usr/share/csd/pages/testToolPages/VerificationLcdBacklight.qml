/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import ".."

CsdTestPage {
    id: page

    property bool ambientLightSensorEnabled
    property int originalBrightness

    function resetOriginalValues() {
        displaySettings.ambientLightSensorEnabled = ambientLightSensorEnabled
        displaySettings.brightness = originalBrightness
    }

    function startTest() {
        hintText.visible = false
        okButton.visible = false
        rect.color = "white"

        displaySettings.brightness = 1

        testTimer.start()
    }

    onStatusChanged: {
        if (status === PageStatus.Deactivating) {
            resetOriginalValues()
        }
    }

    Component.onDestruction: {
        resetOriginalValues()
    }

    Rectangle {
        id: rect

        anchors.fill: parent
        color: Theme.overlayBackgroundColor
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        CsdPageHeader {
            //% "LCD backlight"
            title: qsTrId("csd-he-lcd_backlight")
        }
        DescriptionItem {
            id: hintText

            //% "This test will display a white screen, after which the screen should become visibly dimmer. Press 'Start' to test."
            text: qsTrId("csd-la-verification_lcd_backglight_operation_hint_description")
        }
    }
    BottomButton {
        id: okButton
        //% "Start"
        text: qsTrId("csd-la-start")
        onClicked: startTest()
    }

    Label {
        id: buttonText

        visible: false
        font.pixelSize: Theme.fontSizeLarge
        x: Theme.paddingLarge
        width: parent.width - 2*x
        anchors.verticalCenter: parent.verticalCenter

        //% "Did screen backlight get dimmer?"
        text: qsTrId("csd-la-is_screen_dim")
        wrapMode: Text.Wrap
    }

    ButtonLayout {
        id: buttonRow
        anchors {
            top: buttonText.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        rowSpacing: Theme.paddingMedium
        visible: false

        PassButton {
            onClicked: {
                setTestResult(true)
                testCompleted(true)
            }
        }
        FailButton {
            onClicked: {
                setTestResult(false)
                testCompleted(true)
            }
        }
    }

    Timer {
        id: testTimer
        interval: 4000
        onTriggered: {
            rect.color = Theme.overlayBackgroundColor
            buttonText.visible = true
            buttonRow.visible = true
            resetOriginalValues()
            if (runInTests) {
                setTestResult(true)
                testCompleted(true)
            }
        }
    }

    DisplaySettings {
        id: displaySettings
        onPopulatedChanged: {
            // Save existing backlight settings
            page.ambientLightSensorEnabled = displaySettings.ambientLightSensorEnabled
            originalBrightness = displaySettings.brightness
            // Max out the brightness before test
            displaySettings.brightness = displaySettings.maximumBrightness
            // Also disable the ambient light sensor.
            displaySettings.ambientLightSensorEnabled = false

            if (runInTests) {
                startTest()
            }
        }
    }
}
