/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0

Page {
    property int testMode
    readonly property bool runInTests: testMode === Features.RunInTests
    property bool isContinueTest
    property var parameters
    property var customTestResultHandler
    property var customTestCompletedHandler

    signal testFinished(bool passFail)

    // Use delayed popping when exiting test case during run-in-tests
    // See e.g. VerificationReboot or VerificationFrontCameraReboot onTestStopped handlers
    function exit(popImmediately) {
        if (popImmediately) {
            pageStack.pop()
        } else if (isContinueTest || runInTests) {
            timer.start()
        }
    }

    function setTestResult(passFail) {
        if (customTestResultHandler) {
            if (typeof customTestResultHandler != "function") {
                console.warn("customTestResultHandler is not a function. Should be a function that takes one argument.")
            } else {
                customTestResultHandler(passFail)
            }
        } else {
            testFinished(passFail)
        }
    }

    function testCompleted(popImmediately) {
        if (customTestCompletedHandler) {
            if (typeof customTestCompletedHandler != "function") {
                console.warn("customTestCompletedHandler is not a function. Should be a function that takes one argument.")
            } else {
                customTestCompletedHandler(popImmediately)
            }
        } else {
            exit(popImmediately)
        }
    }

    Timer {
        id: timer

        interval: 2000
        onTriggered: pageStack.pop()
    }
}
