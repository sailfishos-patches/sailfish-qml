/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.KeepAlive 1.2
import Nemo.Configuration 1.0
import Nemo.Time 1.0
import Sailfish.Silica.private 1.0 as Private
import Csd 1.0
import "testToolPages"

Page {
    id: page

    property bool runInTestPerformed

    property int runInTimeHours: CsdHwSettings.runInTestLength
    property bool _testsStarted
    property bool _showTestTimes
    property bool _showTestsRunningUi
    property bool forever: false

    property variant disabledTests: []

    backNavigation: !_testsStarted

    Component.onCompleted: {
        var dt = testCaseListModel.getOption("DisabledRunInTests")
        if (dt)
            disabledTests = dt.split(",")
    }

    function _startTests() {
        // ensure tests continue if the system unexpectedly reboots
        rebootTestData.testMode = Features.RunInTests
        frontCameraRebootTestData.testMode = Features.RunInTests
        systemd.enableAutostart()

        testCaseListModel.clearResults()
        testData.running = true
        testData.iterations = -1
        testData.forever = forever
        testData.duration = runInTimeHours
        testData.startTime = new Date
        testData.endTime = new Date(testData.startTime.valueOf() + testData.duration*60*60*1000)
        testData.testIndex = -1
        page._testsStarted = true
        page._showTestsRunningUi = false
        page._showTestTimes = false
        if (testData.forever)
            testCaseListModel.log("", "Starting run-in tests, duration forever")
        else
            testCaseListModel.log("", "Starting run-in tests, duration " + testData.duration + " hours")
        _triggerNextTest(false)
    }

    function _showTest(url) {
        testCaseListModel.log(url, "starting")

        var parameters = {}
        var supportedParameters = testCaseListModel.getTestParameters(url)
        for (var i in supportedParameters) {
            parameters[supportedParameters[i]] = testCaseListModel.getTestParameter(url, supportedParameters[i], 2)
        }

        pageStack.animatorPush(Qt.resolvedUrl("testToolPages/" + url + ".qml"),
                               {
                                   "testMode": Features.RunInTests,
                                   "parameters": parameters
                               })
    }

    // Disallow minimising CSD application when tests are run.
    // Press "Stop" button to enable system gestures.
    Private.WindowGestureOverride { active: _testsStarted }

    DisplayBlanking {
        preventBlanking: page._testsStarted
    }

    Connections {
        target: pageStack
        onCurrentPageChanged: {
            if (testData.testIndex < 0 || !pageStack.currentPage.hasOwnProperty("testFinished"))
                return

            var url = testCaseListModel.get(testData.testIndex).url
            pageStack.currentPage.testFinished.connect(function(url) {
                return function(passFail) {
                    testCaseListModel.setResult(url, passFail)
                    testCaseListModel.log(url, passFail ? "passed" : "failed")
                }
            }(url))
        }
    }

    function _stopTest() {
        systemd.disableAutostart()
        testData.endTime = new Date
        runInTestPerformed = true
        _testsStarted = false
        _showTestsRunningUi = false
        testData.testIndex = -1
        testData.running = false
    }

    function _triggerNextTest(delayStart) {
        var now = new Date
        if (!testData.forever && (now > testData.endTime)) {
            testCaseListModel.log("", "Run-in tests completed")
            _stopTest()
            // Increment also upon the last iterations.
            testData.iterations += 1
            return
        }

        var count = 0

        while (count < testCaseListModel.count) {
            testData.testIndex = (testData.testIndex + 1) % testCaseListModel.count

            if (testData.testIndex === 0) {
                testData.iterations += 1
                if (testData.iterations > 0)
                    testCaseListModel.log("", "Completed iteration " + testData.iterations)
            }

            count += 1

            var modelData = testCaseListModel.get(testData.testIndex)
            if (modelData.supported && page.disabledTests.indexOf(modelData.url) === -1) {
                if (delayStart) {
                    _showTestsRunningUi = true
                    startTestDelay.start()
                } else {
                    _showTest(modelData.url)
                }
                return
            }
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            if (testData.running) {
                page._testsStarted = true
                if (!rebootTestData.running && !frontCameraRebootTestData.running) {
                    testCaseListModel.log("", "Run-in tests were interrupted")
                }
            }
            if (rebootTestData.running || frontCameraRebootTestData.running) {
                testCaseListModel.log("", "Continuing run-in tests after reboot")
            } else if (_testsStarted) {
                var url = testCaseListModel.get(testData.testIndex).url
                testCaseListModel.log(url, "completed")
                _triggerNextTest(true)
            }
        } else if (status == PageStatus.Inactive) {
            if (_testsStarted) {
                _showTestsRunningUi = true
            }
        }
    }

    SilicaListView {
        id: listView
        
        anchors.fill: parent
        model: testCaseListModel

        PullDownMenu {
            MenuItem {
                text: page._showTestTimes
                        //% "Hide test times"
                      ? qsTrId("csd-me-hide_test_times")
                        //% "Show test times"
                      : qsTrId("csd-me-show_test_times")

                enabled: listView.count > 0
                onClicked: page._showTestTimes = !page._showTestTimes
            }

            MenuItem {
                //% "Clear results"
                text: qsTrId("csd-me-clear_results")
                enabled: listView.count > 0
                onClicked: testCaseListModel.clearResults()
            }

            MenuItem {
                //% "Start"
                text: qsTrId("csd-me-start")
                enabled: !_showTestsRunningUi && listView.count > 0
                         && page.disabledTests.length !== listView.count
                onClicked: page._startTests()
            }
        }

        header: Column {
            width: listView.width

            PageHeader {
                //% "Run-in tests"
                title: qsTrId("csd-he-runin_tests")
            }

            Column {
                width: parent.width
                visible: !_showTestsRunningUi
                enabled: visible

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    //% "Run-in tests are run in a loop for the specified test run time. You can stop the run-in test loop between tests by tapping the 'Stop' button."
                    text: qsTrId("csd-la-runin_testing_disclaimer")
                }

                TextSwitch {
                    id: foreverSwitch

                    //% "Run forever"
                    text: qsTrId("csd-la-runin_run_forever")
                    checked: forever
                    onCheckedChanged: forever = checked
                }

                Row {
                    width: parent.width
                    visible: opacity > 0
                    spacing: Theme.paddingMedium
                    opacity: foreverSwitch.checked ? 0.0 : 1.0
                    height: foreverSwitch.checked ? 0 : implicitHeight

                    Behavior on opacity { FadeAnimation { } }
                    Behavior on height { NumberAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }

                    TextField {
                        id: runInTimeField

                        //% "Test run time (hours)"
                        label: qsTrId("csd-la-runin_test_run_time")

                        //% "Hours"
                        placeholderText: qsTrId("csd-ph-hours")

                        text: CsdHwSettings.runInTestLength
                        onTextChanged: runInTimeHours = parseInt(text)

                        width: parent.width - hoursDown.width - hoursUp.width - 2*parent.spacing
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 1 }

                        function increment() {
                            text = parseInt(text) + 1
                        }

                        function decrement() {
                            var time = parseInt(text)
                            if (time > 1)
                                text = time - 1
                        }
                    }

                    IconButton {
                        id: hoursDown

                        icon.source: "image://theme/icon-m-remove"
                        onReleased: {
                            if (repeatTimer.running)
                                repeatTimer.stop()
                            else
                                runInTimeField.decrement()
                        }
                        onPressAndHold: repeatTimer.start()
                    }

                    IconButton {
                        id: hoursUp

                        icon.source: "image://theme/icon-m-add"
                        onReleased: {
                            if (repeatTimer.running)
                                repeatTimer.stop()
                            else
                                runInTimeField.increment()
                        }
                        onPressAndHold: repeatTimer.start()
                    }

                    Timer {
                        id: repeatTimer

                        interval: 250
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: {
                            if (hoursUp.pressed)
                                runInTimeField.increment()
                            else if (hoursDown.pressed)
                                runInTimeField.decrement()
                            else
                                stop()
                        }
                    }
                }
            }

            SectionHeader {
                //% "Last test"
                text: qsTrId("csd-la-runin_last_test")
                visible: !_testsStarted
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                visible: runInTestPerformed || _showTestsRunningUi

                Label {
                    //% "Start time: %1"
                    text: qsTrId("csd-la-start_time").arg(Format.formatDate(testData.startTime, Format.Timepoint))
                }

                Label {
                    //% "End time: %1"
                    text: qsTrId("csd-la-end_time").arg(runInTestPerformed || !testData.forever
                                                        ? Format.formatDate(testData.endTime, Format.Timepoint)
                                                          //% "forever"
                                                        : qsTrId("csd-la-runin_forever"))
                }

                Label {
                    visible: _showTestsRunningUi && !testData.forever
                    //% "Remaining time: %1"
                    text: qsTrId("csd-la-runin_remaining_time").arg(Format.formatDuration(Math.max(0, (testData.endTime - wallClock.time)/1000),
                                                                                          Format.DurationLong))

                    WallClock {
                        id: wallClock
                        enabled: Qt.application.active
                        updateFrequency: WallClock.Second
                    }
                }

                Label {
                    //% "Completed iterations: %1"
                    text: qsTrId("csd-la-runin_completed_iterations").arg(testData.iterations)
                }

                Label {
                    visible: startTestDelay.running
                    text: startTestDelay.running
                            //% "Starting next test in %1 seconds"
                          ? qsTrId("csd-la-start_next_test_in").arg(startTestDelay.remaining)
                          : " "
                }
                Item {
                    width: parent.width
                    height: Theme.paddingMedium
                }
            }

            Button {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                visible: _showTestsRunningUi

                //% "Stop"
                text: qsTrId("csd-la-stop")
                onClicked: {
                    testCaseListModel.log("", "Stopping run-in tests")
                    startTestDelay.stop()
                    page._stopTest()
                }
            }

            Item {
                width: parent.width
                height: Theme.paddingMedium
                visible: _showTestsRunningUi
            }
            SectionHeader {
                //% "Test cases"
                text: qsTrId("csd-la-runin_testcases")
            }
        }

        delegate: RunInTestItem {
            enabled: !_testsStarted
            opacity: _testsStarted && !selected ? Theme.opacityHigh : 1

            selected: page.disabledTests === undefined ||
                      page.disabledTests.indexOf(url) === -1

            showTestDurationSlider: page._showTestTimes &&
                                    testCaseListModel.getTestParameters(url).indexOf("RunInTestTime") !== -1
            sliderValue: testCaseListModel.getTestParameter(url, "RunInTestTime", 20)
            onCurrentSliderValueChanged: testCaseListModel.setTestParameter(url, "RunInTestTime", sliderValue)

            onClicked: {
                var dt
                if (selected) {
                    dt = page.disabledTests === undefined ? [] : page.disabledTests
                    dt.push(url)
                } else {
                    dt = []
                    for (var i = 0; i < page.disabledTests.length; ++i) {
                        if (url !== page.disabledTests[i])
                            dt.push(page.disabledTests[i])
                    }
                }
                testCaseListModel.setOption("DisabledRunInTests", dt.join())
                page.disabledTests = dt
            }
        }

        footer: Item { width: 1; height: Theme.paddingLarge }

        ViewPlaceholder {
            enabled: listView.count === 0
            //% "No run-in tests"
            text: qsTrId("csd-la-no_run_in_tests")
        }

        VerticalScrollDecorator { }
    }


    ConfigurationGroup {
        id: testData

        property bool running
        property date startTime
        property date endTime
        property bool forever
        property int iterations
        property int duration
        property int testIndex

        path: "/apps/csd/runin"
    }

    ConfigurationGroup {
        id: rebootTestData

        property bool running
        property int testMode

        path: "/apps/csd/reboot"
    }

    ConfigurationGroup {
        id: frontCameraRebootTestData

        property bool running
        property int testMode

        path: "/apps/csd/front_camera_reboot"
    }

    Timer {
        id: startTestDelay

        property int delay: 5
        property int remaining: delay

        interval: 1000
        repeat: true

        onTriggered: {
            remaining -= 1
            if (remaining === 0) {
                stop()
                remaining = delay
                _showTest(testCaseListModel.get(testData.testIndex).url)
            }
        }
    }

    TestCaseListModel {
        id: testCaseListModel

        objectName: "runInTestsModel"
        testMode: Features.RunInTests
    }

    AppAutoStart {
        id: systemd
    }
}

