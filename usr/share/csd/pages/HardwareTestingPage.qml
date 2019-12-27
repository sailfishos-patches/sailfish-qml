/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import "testToolPages"

Page {
    id: page

    property bool continuousTesting
    property bool continuousTestPerformed
    property alias testMode: testCaseListModel.testMode

    property bool _testsStarted
    property int testIndex: -1

    function _showTest(url) {
        var obj = pageStack.animatorPush(Qt.resolvedUrl("testToolPages/" + url + ".qml"),
                                  {
                                      "testMode": testMode,
                                      "isContinueTest": continuousTesting
                                  })
        obj.pageCompleted.connect(function(test) {
            test.testFinished.connect(function(url) {
                return function(passFail) {
                    testCaseListModel.setResult(url, passFail)
                }
            }(url))
        })
    }

    Connections {
        target: pageStack
        onCurrentPageChanged: {
            if (testIndex < 0 || !pageStack.currentPage.hasOwnProperty("testFinished"))
                return

            var url = testCaseListModel.get(testIndex).url
            pageStack.currentPage.testFinished.connect(function(url) {
                return function(passFail) {
                    testCaseListModel.setResult(url, passFail)
                }
            }(url))
        }
    }

    function _triggerNextTest() {
        while (testIndex < testCaseListModel.count - 1) {
            testIndex += 1

            var test = testCaseListModel.get(testIndex)

            // We have FactoryUtils.Pass, but that's actually "01" and the
            // test.result == "01" comparison would fail.
            if (test.result == 1) {
                testCaseListModel.log(test.url, " already passed, skipping")
                continue
            }

            if (test.supported) {
                var url = test.url
                _showTest(url)
                return
            }
        }

        continuousTestPerformed = true
        continuousTesting = false
        _testsStarted = false
        testIndex = -1
    }

    onStatusChanged: {
        if (status == PageStatus.Active && continuousTesting && _testsStarted)
            _triggerNextTest()
    }

    SilicaListView {
        id: listView

        model: testCaseListModel

        interactive: !continuousTestConfirmation.visible
        visible: !continuousTesting

        PullDownMenu {
            MenuItem {
                //% "Clear test results"
                text: qsTrId("csd-me-clear_test_results")
                enabled: true
                onClicked: testCaseListModel.clearResults()
            }

            MenuItem {
                //% "Start continuous testing"
                text: qsTrId("csd-me-start_continuous_testing")
                visible: testMode === Features.FactoryTests
                onClicked: {
                    continuousTestConfirmation.popOnCancel = false
                    continuousTesting = true
                }
            }
        }

        anchors.fill: parent
        header: PageHeader {
            //% "Hardware tests"
            title: qsTrId("csd-he-hardware_tests")
        }

        delegate: HardwareTestItem {
            onClicked: _showTest(url)
        }

        footer: Item { width: 1; height: Theme.paddingLarge }

        section {
            property: "group"
            criteria: ViewSection.FullString
            delegate: SectionHeader {
                text: section
            }
        }
        
        VerticalScrollDecorator {}
    }

    Column {
        visible: continuousTesting
        anchors.centerIn: parent
        width: parent.width
        spacing: Theme.paddingMedium

        BusyIndicator {
            anchors.horizontalCenter: parent.horizontalCenter
            running: continuousTesting
            size: BusyIndicatorSize.Large
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            //% "Continuous testing"
            text: qsTrId("csd-la-continuous_tests")
        }
    }

    Rectangle {
        id: continuousTestConfirmation

        property bool popOnCancel: true

        anchors.fill: parent
        color: Theme.overlayBackgroundColor

        visible: opacity > 0
        opacity: continuousTesting && !_testsStarted ? 1 : 0

        Behavior on opacity { FadeAnimation {} }

        Column {
            width: parent.width
            spacing: Theme.paddingLarge

            CsdPageHeader {
                //% "Continuous testing"
                title: qsTrId("csd-he-continuous_testing")
            }

            DescriptionItem {
                title: ""
                //% "Are you sure you want to start the continuous tests?<br><br>This will run all of the tests, which takes some time. You will not be able to perform other operations until all of the tests have finished."
                text: qsTrId("csd-la-continued_testing_warning")
            }
        }

        TextSwitch {
            id: skipSwitch
            //% "Skip tests already passed"
            text: qsTrId("csd-la-skip_passed_tests")
            anchors.bottom: cancelButton.top
            checked: true
        }

        BottomButton {
            id: cancelButton
            //% "Cancel"
            text: qsTrId("csd-la-cancel")
            anchors.bottom: startButton.top
            onClicked: {
                if (continuousTestConfirmation.popOnCancel)
                    pageStack.pop()
                else
                    continuousTesting = false
            }
        }

        BottomButton {
            id: startButton

            //% "Start"
            text: qsTrId("csd-la-start")
            onClicked: {
                if (!skipSwitch.checked)
                    testCaseListModel.clearResults()
                page._testsStarted = true
                page._triggerNextTest()
            }
        }
    }

    TestCaseListModel {
        id: testCaseListModel
        objectName: "hardwareTestModel"
    }
}
