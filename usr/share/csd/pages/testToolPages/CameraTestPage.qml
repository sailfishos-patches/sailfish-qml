/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.4
import Sailfish.Policy 1.0
import Csd 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.time 1.0
import ".."

CsdTestPage {
    id: page

    property alias videoOutput: videoOutput
    property alias camera: camera
    property alias imagePreview: photoPreview
    property bool focusBeforeCapture
    readonly property bool autoCapture: runInTests && !paused

    property size viewfinderResolution: Qt.size(width, height)
    property size imageCaptureResolution: Qt.size(width, height)

    readonly property bool backFaceCameraActive: camera.position === Camera.BackFace
    property bool switchBetweenFrontAndBack

    property bool active: true
    readonly property bool paused: !Qt.application.active
    readonly property bool canActivateCamera: _completed && status == PageStatus.Active && active && policy.value

    readonly property bool _focusEnabled: focusBeforeCapture && (camera.focus.focusMode == Camera.FocusAuto || camera.focus.focusMode == Camera.FocusContinuous)
    property bool _imageCaptureFailed
    property bool _focusing
    property bool _completed
    property bool _unloadCamera

    function resumeTesting() {
        autoCaptureFailTimer.restart()
        _deleteCapturedImage()
        _focusCamera(true)
    }

    onPausedChanged: {
        if (!paused) {
            camera.unloadCaptureFinished = false
            resumeTesting()
        } else {
            camera.imageCapture.cancelCapture()
            camera.unloadCaptureFinished = true
            autoCaptureFailTimer.stop()
        }
    }

    function reload() {
        if (page._completed) {
            page._unloadCamera = true
        }
    }

    function _deleteCapturedImage() {
        if (photoPreview.source == "") {
            return
        }
        var path = photoPreview.source
        photoPreview.source = ""
        if (!csdUtils.removeFile(path)) {
            console.log("Unable to delete captured photo at path:", path)
        } else {
            console.log("Deleted captured photo:", path)
        }
    }

    function _focusCamera(delay) {
        _focusing = true
        if (delay) {
            focusDelay.start()
        } else {
            camera.searchAndLock()
        }
    }

    onStatusChanged: {
        // Activating the camera may cause the UI to block for a short time. This is currently
        // unavoidable. The page is static so maybe the user won't notice :)
        if (status == PageStatus.Deactivating && policy.value) {
            camera.cameraState = camera.cameraState
            _deleteCapturedImage()
        }
    }

    CsdUtils {
        id: csdUtils
    }

    PolicyValue {
        id: policy
        policyType: PolicyValue.CameraEnabled
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: policy.value && camera.cameraState !== Camera.ActiveState
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent

        source: Camera {
            id: camera

            readonly property string imageCapturePath: "/tmp/csd-camera-capture.jpg"
            property bool unloadCaptureFinished

            function captureImage() {
                if (!paused && imageCapture.ready && policy.value) {
                    _focusing = false
                    imageCapture.captureToLocation(imageCapturePath)
                }
            }

            // Starting in unloaded state does not block the page activation transition.
            cameraState: canActivateCamera && !page._unloadCamera && !unloadCaptureFinished
                        ? Camera.ActiveState
                        : Camera.UnloadedState
            captureMode: Camera.CaptureStillImage
            focus.focusMode: backFaceCameraActive ? CsdHwSettings.intValue("BackCamera/FocusMode", Camera.FocusAuto)
                                                  : CsdHwSettings.intValue("FrontCamera/FocusMode", Camera.FocusHyperfocal)
            viewfinder.resolution: page.viewfinderResolution

            onCameraStateChanged: {
                if (autoCapture && _focusEnabled && cameraState === Camera.ActiveState && policy.value) {
                    _focusCamera(true)
                }
            }

            imageCapture {
                resolution: page.imageCaptureResolution

                onImageSaved: {
                    if (paused) {
                        camera.unlock()
                        return
                    }

                    console.log("Save captured photo to path:", path)
                    _deleteCapturedImage()
                    photoPreview.source = path

                    if (switchBetweenFrontAndBack) {
                        reload()
                        camera.position = ((camera.position === Camera.BackFace) ? Camera.FrontFace : Camera.BackFace)
                        if (!focusBeforeCapture) {
                            _focusing = false
                        }
                    }
                }

                onCaptureFailed: {
                    if (paused && policy.value) {
                        camera.unlock()
                        return
                    }

                    _imageCaptureFailed = true
                    console.log("Camera capture failed!")

                    if (autoCapture) {
                        setTestResult(false)
                        testCompleted(true)
                    }
                }
            }

            onLockStatusChanged: {
                if (paused && (lockStatus != Camera.Unlocked)) {
                    unlock()
                    return
                }

                if (_focusEnabled) {
                    if (lockStatus === Camera.Unlocked) {
                        if (_focusing) {
                            console.log("Camera failed to get focus, retrying ...")
                            _focusCamera(true)
                        } else if (autoCapture) {
                            _focusCamera(true)
                        }
                    } else if (lockStatus === Camera.Locked) {
                        camera.captureImage()
                    }
                } else if (lockStatus === Camera.Searching) {
                    camera.captureImage()
                }
            }
        }
    }

    Image {
        id: photoPreview

        // rotate and stretch to fit screen
        anchors.centerIn: parent
        sourceSize.height: 1.5 * height
        rotation: camera.position === Camera.FrontFace
                ? camera.orientation
                : -camera.orientation

        width:  rotation % 180 ? Screen.height : Screen.width
        height: rotation % 180 ? Screen.width  : Screen.height
        fillMode: Image.PreserveAspectFit

        // don't load cached versions of previously deleted images
        cache: false

        visible: photoPreview.source != "" || _imageCaptureFailed

        onStatusChanged: {
            if (autoCapture) {
                if (status === Image.Error) {
                    console.log("Could not load captured image at path", source)
                    setTestResult(false)
                    testCompleted(true)
                } else if (status === Image.Ready) {
                    setTestResult(true)

                    if (testTime.remainingTestTime <= 0) {
                        testCompleted(true)
                    } else if (!paused) {
                        resumeTesting()
                    }
                }
            }
        }
    }

    Rectangle {
        id: buttonBackground

        color: Theme.overlayBackgroundColor
        height: Theme.itemSizeMedium
        width: parent.width
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Theme.paddingLarge
        visible: bottomButton.visible || passFailButtons.visible
    }

    ButtonLayout {
        id: passFailButtons

        anchors {
            verticalCenter: buttonBackground.verticalCenter
            horizontalCenter: parent.horizontalCenter
        }

        rowSpacing: Theme.paddingLarge*3
        visible: photoPreview.visible && !autoCapture

        PassButton {
            onClicked: {
                if (policy.value) {
                    camera.cameraState = Camera.UnloadedState
                }
                setTestResult(true)
                testCompleted(true)
            }
        }
        FailButton {
            onClicked: {
                if (policy.value) {
                    camera.cameraState = Camera.UnloadedState
                }
                setTestResult(false)
                testCompleted(true)
            }
        }
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: resolutionInfo.top
            bottomMargin: Theme.paddingLarge
        }
        visible: _focusing
        spacing: Theme.paddingLarge

        BusyIndicator {
            size: BusyIndicatorSize.Medium
            running: _focusing
        }

        Label {
            //: Shown while camera is getting focus
            //% "Focusing"
            text: qsTrId("csd-la-camera_focusing")
            font.bold: true
            font.pixelSize: Theme.fontSizeLarge
        }
    }

    Column {
        id: resolutionInfo
        anchors {
            bottom: bottomButton.top
            bottomMargin: Theme.paddingLarge
        }
        width: parent.width

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            //: Resolution of camera viewfinder. %1 = width, %2 = height
            //% "Viewfinder: %1 x %2"
            text: qsTrId("csd-la-camera_viewfinder_resolution").arg(viewfinderResolution.width).arg(viewfinderResolution.height)
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            font.bold: true
            //: Resolution of captured camera image. %1 = width, %2 = height
            //% "Image: %1 x %2"
            text: qsTrId("csd-la-camera_image_resolution").arg(imageCaptureResolution.width).arg(imageCaptureResolution.height)
        }

        Label {
            visible: autoCapture
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter

            //% "Remaining: %1"
            text: qsTrId("csd-la-test_time_remaining").arg(Format.formatDuration(testTime.remainingTestTime, Format.DurationShort))
        }
    }

    BottomButton {
        id: bottomButton
        visible: !autoCapture && photoPreview.source == "" && !_imageCaptureFailed && policy.value

        //% "Shoot"
        text: qsTrId("csd-la-shoot")
        onClicked: {
            if (_focusEnabled) {
                _focusCamera(false)
            } else {
                camera.captureImage()
            }
        }
    }

    Timer {
        id: focusDelay

        interval: 1000
        onTriggered: if (policy.value) camera.searchAndLock()
    }

    Timer {
        id: autoCaptureFailTimer

        interval: 20000
        running: false

        Component.onCompleted: {
            if (autoCapture) {
                running = true
            }
        }

        onTriggered: {
            setTestResult(false)
            testCompleted(true)
        }
    }

    Timer {
        id: reloadTimer
        interval: 10
        running: page._unloadCamera && (camera.cameraStatus == Camera.UnloadedStatus)
        onTriggered: {
            page._unloadCamera = false
        }
    }

    WallClock {
        id: testTime

        readonly property var testStartTime: new Date
        readonly property double remainingTestTime: Math.max(_TEST_TIME*60 - (time - testStartTime) / 1000, 0)

        // Test time in minutes
        property double _TEST_TIME: page.runInTests
                                    ? page.parameters["RunInTestTime"] : 0

        updateFrequency: WallClock.Second
    }

    Component.onCompleted: _completed = true
}
