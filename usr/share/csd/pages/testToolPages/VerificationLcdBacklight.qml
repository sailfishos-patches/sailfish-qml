/*
 * Copyright (c) 2016 - 2022 Jolla Ltd.
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
    property bool originalValuesSaved
    property bool testStarted
    property bool testStopped
    readonly property bool testRunning: testStarted && !testStopped

    function resetOriginalValues() {
        if (originalValuesSaved) {
            displaySettings.ambientLightSensorEnabled = ambientLightSensorEnabled
            displaySettings.brightness = originalBrightness
        }
    }

    function setupTest() {
        // Save original backlight settings
        if (!originalValuesSaved) {
            ambientLightSensorEnabled = displaySettings.ambientLightSensorEnabled
            originalBrightness = displaySettings.brightness
            originalValuesSaved = true
        }

        // Max out the brightness before test
        displaySettings.brightness = displaySettings.maximumBrightness
        // Also disable the ambient light sensor.
        displaySettings.ambientLightSensorEnabled = false

        if (runInTests) {
            startTest()
        }
    }

    function startTest() {
        testStarted = true
        testStartTimer.start()
    }

    function stopTest() {
        testStopped = true
        resetOriginalValues()
        if (runInTests) {
            completeTest(true)
        }
    }

    function completeTest(result) {
        setTestResult(result)
        testCompleted(true)
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
        anchors.fill: parent
        color: testRunning ? "white" : Theme.overlayBackgroundColor
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        CsdPageHeader {
            //% "LCD backlight"
            title: qsTrId("csd-he-lcd_backlight")
        }
        DescriptionItem {
            visible: !testStarted

            //% "This test will display a white screen, after which the screen should become visibly dimmer. Press 'Start' to test."
            text: qsTrId("csd-la-verification_lcd_backglight_operation_hint_description")
        }
    }
    BottomButton {
        visible: !testStarted
        enabled: originalValuesSaved
        //% "Start"
        text: qsTrId("csd-la-start")
        onClicked: startTest()
    }

    Label {
        id: buttonText

        visible: testStopped
        font.pixelSize: Theme.fontSizeLarge
        x: Theme.paddingLarge
        width: parent.width - 2*x
        anchors.verticalCenter: parent.verticalCenter

        //% "Did screen backlight get dimmer?"
        text: qsTrId("csd-la-is_screen_dim")
        wrapMode: Text.Wrap
    }

    ButtonLayout {
        anchors {
            top: buttonText.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        rowSpacing: Theme.paddingMedium
        visible: testStopped

        PassButton {
            onClicked: completeTest(true)
        }
        FailButton {
            onClicked: completeTest(false)
        }
    }

    Timer {
        // Hold white screen at maximum brightness for a while to
        // calm things down and thus highlight the dimming when it
        // actually commences.
        id: testStartTimer
        interval: 1000
        onTriggered: {
            displaySettings.brightness = 1
            testStopTimer.start()
        }
    }

    Timer {
        // When there are brightness setting changes (like what we have
        // here), mce drives the fade in/out through in 600 ms.
        //
        // Waiting a bit longer than that yields stable state also at
        // the minimum brightness end.
        id: testStopTimer
        interval: 600 + 1000
        onTriggered: stopTest()
    }

    DisplaySettings {
        id: displaySettings
        onPopulatedChanged: setupTest()
    }
}
