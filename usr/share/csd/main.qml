/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import Nemo.Configuration 1.0
import Csd 1.0
import "pages"

ApplicationWindow {
    initialPage: Component { FirstPage {} }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All
    _backgroundVisible: false

    Rectangle {
        anchors.fill: parent
        color: Theme.overlayBackgroundColor
        z: -1
    }

    DBusAdaptor {
        service: "com.jolla.csd"
        iface: "com.jolla.csd"
        path: "/com/jolla/csd"

        function show() {
            activate()
        }

        function continueRebootTest() {
            if (!rebootTestData.running && !runInTestData.running && !frontCameraRebootTestData.running) {
                console.log("Not running reboot, front camera with reboot or run-in tests, cannot continue.")
                systemd.disableAutostart()
                return
            }

            if (pageStack.currentPage.objectName === "disclaimer")
                pageStack.navigateForward(PageStackAction.Immediate)

            while (pageStack.depth > 1)
                pageStack.navigateBack(PageStackAction.Immediate)

            var runInTestPagePushed = false
            switch (rebootTestData.testMode) {
            case Features.RunInTests:
                pageStack.push(Qt.resolvedUrl("pages/RunInTestPage.qml"), { }, PageStackAction.Immediate)
                runInTestPagePushed = true
                break
            case Features.FactoryTests:
            case Features.AllTests:
                pageStack.push(Qt.resolvedUrl("pages/HardwareTestingPage.qml"),
                               {
                                   "continuousTesting": rebootTestData.continuousTesting,
                                   "testMode": rebootTestData.testMode
                               }, PageStackAction.Immediate)
                break
            default:
                console.log("Unknown test mode", rebootTestData.testMode)
                return
            }

            if (rebootTestData.running) {
                pageStack.push(Qt.resolvedUrl("pages/testToolPages/VerificationReboot.qml"),
                               {
                                   "testMode": rebootTestData.testMode,
                                   "isContinueTest": rebootTestData.continuousTesting
                               },
                               PageStackAction.Immediate)
            } else if (frontCameraRebootTestData.running) {
                if (!runInTestPagePushed) {
                    pageStack.push(Qt.resolvedUrl("pages/RunInTestPage.qml"), { }, PageStackAction.Immediate)
                }

                pageStack.push(Qt.resolvedUrl("pages/testToolPages/VerificationFrontCameraReboot.qml"),
                               {
                                   "testMode": frontCameraRebootTestData.testMode,
                                   "isContinueTest": frontCameraRebootTestData.continuousTesting
                               },
                               PageStackAction.Immediate)
            }
        }

        function factoryStartup() {
            if (pageStack.currentPage.objectName === "disclaimer")
                pageStack.navigateForward(PageStackAction.Immediate)
        }
    }

    AppAutoStart {
        id: systemd
    }

    ConfigurationGroup {
        id: rebootTestData

        property bool running
        property int testMode
        property bool continuousTesting

        path: "/apps/csd/reboot"
    }

    ConfigurationGroup {
        id: frontCameraRebootTestData

        property bool running
        property int testMode
        property bool continuousTesting

        path: "/apps/csd/front_camera_reboot"
    }

    ConfigurationGroup {
        id: runInTestData

        property bool running

        path: "/apps/csd/runin"
    }
}
