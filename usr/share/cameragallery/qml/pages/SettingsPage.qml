/*
Copyright (c) 2021 Jolla Ltd.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.
  * Neither the name of the Jolla Ltd. nor the names of
    its contributors may be used to endorse or promote products
    derived from this software without specific prior written
    permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL JOLLA LTD OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import QtMultimedia 5.4
import CameraGallery 1.0

Page {
    function formatResolution(size) {
        if (size.width == -1) {
            return "Unselected"
        } else {
            return size.width + "x" + size.height
        }
    }

    property Camera camera

    backgroundColor: "black"

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column

            width: parent.width
            bottomPadding: Theme.paddingLarge

            PageHeader {
                title: "Camera settings"
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: "Note not all the image processing modes exposed by QtMultimedia are supported."
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                wrapMode: Text.Wrap
            }

            ComboBox {
                id: cameraMenu
                label: "Camera"
                menu: ContextMenu {
                    Repeater {
                        model: QtMultimedia.availableCameras.length
                        MenuItem {
                            text: QtMultimedia.availableCameras[model.index].displayName
                            onDelayedClick: {
                                camera.imageCapture.resolution = "-1x-1"
                                camera.videoRecorder.resolution = "-1x-1"
                                cameraMenu.currentIndex = model.index
                                cameraMenu.value = text
                                camera.deviceId = QtMultimedia.availableCameras[model.index].deviceId
                            }
                        }
                    }
                }
            }

            ComboBox {
                id: cameraState

                function name(state) {
                    switch (state) {
                    case Camera.UnloadedState:
                        return "Unloaded"
                    case Camera.LoadedState:
                        return "Loaded"
                    case Camera.ActiveState:
                        return "Active"
                    default:
                        return "Unknown"
                    }
                }
                label: "State"
                value: name(camera.cameraState)
                menu: ContextMenu {
                    Repeater {
                        model: [Camera.UnloadedState, Camera.LoadedState, Camera.ActiveState]

                        MenuItem {
                            text: cameraState.name(modelData)
                            onDelayedClick: camera.cameraState = modelData
                        }
                    }
                }
            }

            DetailItem {
                label: "Status"
                value: {
                    switch (camera.cameraStatus) {
                    case Camera.ActiveStatus:
                        return "Active"
                    case Camera.StartingStatus:
                        return "Starting"
                    case Camera.StoppingStatus:
                        return "Stopping"
                    case Camera.StandbyStatus:
                        return "Stand-by"
                    case Camera.LoadedStatus:
                        return "Loaded"
                    case Camera.LoadingStatus:
                        return "Loading"
                    case Camera.UnloadingStatus:
                        return "Unloading"
                    case Camera.UnloadedStatus:
                        return "Unloaded"
                    case Camera.UnavailableStatus:
                        return "Unavailable"
                    default:
                        return "Unknown"
                    }
                }
            }

            DetailItem {
                label: "Lock status"
                value: {
                    switch (camera.lockStatus) {
                    case Camera.Unlocked:
                        return "Unlocked"
                    case Camera.Searching:
                        return "Searching"
                    case Camera.Locked:
                        return "Locked"
                    default:
                        return "Unknown"
                    }
                }
            }

            DetailItem {
                id: filePathItem
                label: "Availability"
                value: {
                    switch (camera.availability) {
                    case Camera.Available:
                        return "Available"
                    case Camera.Unavailable:
                        return "Unavailable"
                    case Camera.ResourceMissing:
                        return "Resource missing"
                    }
                }
            }

            DetailItem {
                label: "Position"
                value: {
                    switch (camera.position) {
                    case Camera.UnspecifiedPosition:
                        return "Unspecified"
                    case Camera.BackFace:
                        return "Back-facing"
                    case Camera.FrontFace:
                        return "Front-facing"
                    default:
                        return "Unknown"
                    }
                }
            }

            DetailItem {
                label: "Orientation"
                value: camera.orientation + "°"
            }

            ComboBox {
                label: "Resolution"
                value: formatResolution(camera.viewfinder.resolution)

                menu: ContextMenu {
                    Repeater {
                        model: CameraConfigs.supportedViewfinderResolutions
                        MenuItem {
                            text: formatResolution(modelData)
                            onClicked: camera.viewfinder.resolution = modelData
                        }
                    }
                }
            }

            DetailItem {
                label: "Last error code"
                value: camera.errorCode
            }

            DetailItem {
                label: "Error description"
                value: camera.errorString == "" ? "No error"
                                                : camera.errorString
            }

            SectionHeader {
                text: "Zoom"
            }

            Slider {
                minimumValue: 1.0
                maximumValue: camera.maximumDigitalZoom
                value: camera.digitalZoom
                label: "Zoom"
                width: parent.width
                onValueChanged: camera.digitalZoom = value
            }

            SectionHeader {
                text: "Flash"
            }

            DetailItem {
                label: "Ready"
                value: camera.flash.isFlashReady ? "True" : "False"
            }

            ComboBox {
                id: flashMode

                function name(mode) {
                    switch (mode) {
                    case Camera.FlashAuto:
                        return "Auto"
                    case Camera.FlashOff:
                        return "Off"
                    case Camera.FlashOn:
                        return "On"
                    case Camera.FlashRedEyeReduction:
                        return "Red-eye reduction"
                    case Camera.FlashFill:
                        return "Fill"
                    case Camera.FlashTorch:
                        return "Torch"
                    case Camera.FlashVideoLight:
                        return "Video light"
                    case Camera.FlashSlowSyncFrontCurtain:
                        return "Slow sync front curtain"
                    case Camera.FlashSlowSyncRearCurtain:
                        return "Slow sync rear curtain"
                    case Camera.FlashManual:
                        return "Manual"
                    default:
                        return "Unknown"
                    }
                }

                label: "Mode"
                enabled: CameraConfigs.supportedFlashModes.length > 0
                value: name(camera.flash.mode)

                menu: ContextMenu {
                    Repeater {
                        model: CameraConfigs.supportedFlashModes

                        MenuItem {
                            text: flashMode.name(modelData)
                            onClicked: camera.flash.mode = modelData
                        }
                    }
                }
            }

            SectionHeader {
                text: "Capture mode"
            }

            ComboBox {
                id: captureMenu
                label: "Capture mode"
                currentIndex: camera.captureMode
                menu: ContextMenu {
                    MenuItem {
                        text: "Viewfinder"
                        onDelayedClick: camera.captureMode = Camera.CaptureViewfinder
                    }
                    MenuItem {
                        text: "Still Image"
                        onDelayedClick: camera.captureMode = Camera.CaptureStillImage
                    }
                    MenuItem {
                        text: "Video"
                        onDelayedClick: camera.captureMode = Camera.CaptureVideo
                    }
                }
            }

            Column {
                width: parent.width
                visible: camera.captureMode === Camera.CaptureStillImage

                DetailItem {
                    label: "Ready"
                    value: camera.imageCapture.ready ? "True" : "False"
                }

                ComboBox {
                    label: "Resolution"
                    value: formatResolution(camera.imageCapture.resolution)

                    menu: ContextMenu {
                        Repeater {
                            model: CameraConfigs.supportedImageResolutions
                            MenuItem {
                                text: formatResolution(modelData)
                                onClicked: camera.imageCapture.resolution = modelData
                            }
                        }
                    }
                }

                DetailItem {
                    label: "Last image path"
                    value: camera.imageCapture.capturedImagePath
                }

                DetailItem {
                    label: "Description"
                    value: camera.imageCapture.errorString == "" ? "No error"
                                                                 : camera.errorString
                }
            }

            Column {
                width: parent.width
                visible: camera.captureMode === Camera.CaptureVideo

                DetailItem {
                    label: "State"
                    value: {
                        switch (camera.videoRecorder.recorderState) {
                        case CameraRecorder.StoppedState:
                            return "Stopped"
                        case CameraRecorder.RecordingState:
                            return "Recording"
                        default:
                            return "Unknown"
                        }
                    }
                }

                DetailItem {
                    label: "Status"
                    value: {
                        switch (camera.videoRecorder.recorderStatus) {
                        case CameraRecorder.ActiveStatus:
                            return "Active"
                        case CameraRecorder.StartingStatus:
                            return "Starting"
                        case CameraRecorder.RecordingStatus:
                            return "Recording"
                        case CameraRecorder.PausedStatus:
                            return "Paused"
                        case CameraRecorder.FinalizingStatus:
                            return "Finalizing"
                        case CameraRecorder.LoadedStatus:
                            return "Loaded"
                        case CameraRecorder.LoadingStatus:
                            return "Loading"
                        case CameraRecorder.UnloadedStatus:
                            return "Unloaded"
                        case CameraRecorder.UnavailableStatus:
                            return "Unavailable"
                        default:
                            return "Unknown"
                        }
                    }
                }

                ComboBox {
                    label: "Resolution"
                    value: formatResolution(camera.videoRecorder.resolution)

                    menu: ContextMenu {
                        Repeater {
                            model: CameraConfigs.supportedVideoResolutions
                            MenuItem {
                                text: formatResolution(modelData)
                                onClicked: camera.videoRecorder.resolution = modelData
                            }
                        }
                    }
                }

                DetailItem {
                    label: "Actual location"
                    value: camera.videoRecorder.actualLocation
                }

                DetailItem {
                    label: "Output location"
                    value: camera.videoRecorder.outputLocation
                }

                DetailItem {
                    label: "Video bit rate"
                    value: camera.videoRecorder.videoBitRate + "b/s"
                }

                DetailItem {
                    label: "Video codec"
                    value: camera.videoRecorder.videoCodec
                }

                DetailItem {
                    label: "Video encoding mode"
                    value: {
                        switch (camera.videoRecorder.videoEncodingMode) {
                        case CameraRecorder.ConstantQualityEncoding:
                            return "Constant quality"
                        case CameraRecorder.ConstantBitRateEncoding:
                            return "Constant bit rate"
                        case CameraRecorder.AverageBitRateEncoding:
                            return "Average bit rate"
                        default:
                            return "Unknown"
                        }
                    }
                }

                DetailItem {
                    label: "Audio bit rate"
                    value: camera.videoRecorder.audioBitRate + "b/s"
                }

                DetailItem {
                    label: "Audio channels"
                    value: camera.videoRecorder.audioChannels
                }

                DetailItem {
                    label: "Audio codec"
                    value: camera.videoRecorder.audioCodec
                }

                DetailItem {
                    label: "Audio encoding mode"
                    value: {
                        switch (camera.videoRecorder.audioEncodingMode) {
                        case CameraRecorder.ConstantQualityEncoding:
                            return "Constant quality"
                        case CameraRecorder.ConstantBitRateEncoding:
                            return "Constant bit rate"
                        case CameraRecorder.AverageBitRateEncoding:
                            return "Average bit rate"
                        default:
                            return "Unknown"
                        }
                    }
                }

                DetailItem {
                    label: "Audio sample rate"
                    value: camera.videoRecorder.audioSampleRate
                }

                DetailItem {
                    label: "Duration"
                    value: camera.videoRecorder.duration
                }

                DetailItem {
                    label: "Framerate"
                    value: camera.videoRecorder.frameRate.toFixed(1)
                }

                DetailItem {
                    label: "Media container"
                    value: camera.videoRecorder.mediaContainer
                }

                DetailItem {
                    label: "Muted"
                    value: camera.videoRecorder.muted ? "True" : "False"
                }
                DetailItem {
                    label: "Last error code"
                    value: camera.videoRecorder.errorCode
                }

                DetailItem {
                    label: "Error description"
                    value: camera.videoRecorder.errorString == "" ? "No error"
                                                                  : camera.errorString
                }
            }

            SectionHeader {
                text: "Focus"
            }

            ComboBox {
                id: focusMode

                function name(mode) {
                    switch (mode) {
                    case Camera.FocusManual:
                        return "Manual"
                    case Camera.FocusHyperfocal:
                        return "Hyperfocal"
                    case Camera.FocusInfinity:
                        return "Infinity"
                    case Camera.FocusAuto:
                        return "Auto"
                    case Camera.FocusContinuous:
                        return "Continuous"
                    case Camera.FocusMacro:
                        return "Macro"
                    default:
                        return "Unknown"
                    }
                }
                label: "Mode"
                enabled: CameraConfigs.supportedFocusModes.length > 0
                value: name(camera.focus.focusMode)

                menu: ContextMenu {
                    Repeater {
                        model: CameraConfigs.supportedFocusModes

                        MenuItem {
                            text: focusMode.name(modelData)
                            onClicked: camera.focus.focusMode = modelData
                        }
                    }
                }
            }

            ComboBox {
                id: pointMode

                function name(mode) {
                    switch (mode) {
                    case Camera.FocusPointAuto:
                        return "Auto"
                    case Camera.FocusPointCenter:
                        return "Center"
                    case Camera.FocusPointFaceDetection:
                        return "Face detection"
                    case Camera.FocusPointCustom:
                        return "Custom"
                    default:
                        return "Unknown"
                    }
                }
                label: "Point mode"
                enabled: CameraConfigs.supportedFocusPointModes.length > 0
                value: name(camera.focus.focusPointMode)
                menu: ContextMenu {
                    Repeater {
                        model: CameraConfigs.supportedFocusPointModes
                        MenuItem {
                            text: pointMode.name(modelData)
                            onClicked: camera.focus.focusPointMode = modelData
                        }
                    }
                }
            }

            DetailItem {
                label: "Custom focus point"
                value: camera.focus.customFocusPoint.x + ", " + camera.focus.customFocusPoint.y
            }

            SectionHeader {
                text: "Exposure"
            }

            ComboBox {
                id: exposureMode

                function name(mode) {
                    switch (mode) {
                    case Camera.ExposureManual:
                        return "Manual"
                    case Camera.ExposureAuto:
                        return "Auto"
                    case Camera.ExposureNight:
                        return "Night"
                    case Camera.ExposureBacklight:
                        return "Backlight"
                    case Camera.ExposureSpotlight:
                        return "Spotlight"
                    case Camera.ExposureSports:
                        return "Sports"
                    case Camera.ExposureSnow:
                        return "Snow"
                    case Camera.ExposureBeach:
                        return "Beach"
                    case Camera.ExposureLargeAperture:
                        return "Large aperture"
                    case Camera.ExposureSmallAperture:
                        return "Small aperture"
                    case Camera.ExposurePortrait:
                        return "Portrait"
                    case Camera.ExposureAction:
                        return "Action"
                    case Camera.ExposureLandscape:
                        return "Landscape"
                    case Camera.ExposureNightPortrait:
                        return "Night portrait"
                    case Camera.ExposureTheatre:
                        return "Theatre"
                    case Camera.ExposureSunset:
                        return "Sunset"
                    case Camera.ExposureSteadyPhoto:
                        return "Steady photo"
                    case Camera.ExposureFireworks:
                        return "Fireworks"
                    case Camera.ExposureParty:
                        return "Party"
                    case Camera.ExposureCandlelight:
                        return "Candlelight"
                    case Camera.ExposureBarcode:
                        return "Barcode"
                    case Camera.ExposureFlowers:
                        return "Flowers"
                    case Camera.ExposureAR:
                        return "AR"
                    case Camera.ExposureCloseup:
                        return "Closeup"
                    case Camera.ExposureHDR:
                        return "HDR"
                    case Camera.ExposureModeVendor:
                        return "Mode vendor"
                    default:
                        return "Unknown"
                    }
                }
                label: "Mode"
                enabled: CameraConfigs.supportedExposureModes.length > 0
                value: name(camera.exposure.exposureMode)
                menu: ContextMenu {
                    Repeater {
                        model: CameraConfigs.supportedExposureModes
                        MenuItem {
                            text: exposureMode.name(modelData)
                            onClicked: camera.exposure.exposureMode = modelData
                        }
                    }
                }
            }


            /*
              Uncomment when works
            DetailItem {
                label: "Shutter speed"
                value: camera.exposure.shutterSpeed.toFixed(2)
            }

            TextField {
                label: "Manual shutter speed"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                text: camera.exposure.manualShutterSpeed.toFixed(2)
                onTextChanged: camera.exposure.manualShutterSpeed = parseFloat(text)
            }
            */

            Slider {
                minimumValue: -4.0
                maximumValue: 4.0
                stepSize: 1.0
                value: camera.exposure.exposureCompensation
                label: "Compensation"
                valueText: camera.exposure.exposureCompensation.toFixed(1)
                width: parent.width
                onValueChanged: camera.exposure.exposureCompensation = value
            }

            DetailItem {
                label: "ISO"
                value: camera.exposure.iso
            }

            ComboBox {
                label: "Manual ISO"
                enabled: CameraConfigs.supportedIsoSensitivities.length > 0
                value: camera.exposure.manualIso.toString()

                menu: ContextMenu {
                    Repeater {
                        model: CameraConfigs.supportedIsoSensitivities

                        MenuItem {
                            text: modelData.toString()
                            onClicked: camera.exposure.manualIso = modelData
                        }
                    }
                }
            }

            DetailItem {
                label: "Aperture"
                value: camera.exposure.aperture.toFixed(2)
            }

            ComboBox {
                id: meteringMode

                function name(mode) {
                    switch (mode) {
                    case Camera.MeteringMatrix:
                        return "Matrix"
                    case Camera.MeteringAverage:
                        return "Average"
                    case Camera.MeteringSpot:
                        return "Spot"
                    default:
                        return "Unknown"
                    }
                }
                label: "Metering mode"
                enabled: CameraConfigs.supportedMeteringModes.length > 0
                value: name(camera.exposure.meteringMode)
                menu: ContextMenu {
                    Repeater {
                        model: CameraConfigs.supportedMeteringModes

                        MenuItem {
                            text: meteringMode.name(modelData)
                            onClicked: camera.exposure.meteringMode = modelData
                        }
                    }
                }
            }

            DetailItem {
                label: "Spot metering point"
                value: camera.exposure.spotMeteringPoint.x + ", " + camera.exposure.spotMeteringPoint.y
            }

            SectionHeader {
                text: "Image processing"
            }

            ComboBox {
                id: whiteBalanceMode

                function name(mode) {
                    switch (mode) {
                    case CameraImageProcessing.WhiteBalanceManual:
                        return "Manual"
                    case CameraImageProcessing.WhiteBalanceAuto:
                        return "Auto"
                    case CameraImageProcessing.WhiteBalanceSunlight:
                        return "Sunlight"
                    case CameraImageProcessing.WhiteBalanceCloudy:
                        return "Cloudy"
                    case CameraImageProcessing.WhiteBalanceShade:
                        return "Shade"
                    case CameraImageProcessing.WhiteBalanceTungsten:
                        return "Tungsten"
                    case CameraImageProcessing.WhiteBalanceFluorescent:
                        return "Fluorescent"
                    case CameraImageProcessing.WhiteBalanceFlash:
                        return "Flash"
                    case CameraImageProcessing.WhiteBalanceSunset:
                        return "Sunset"
                    case CameraImageProcessing.WhiteBalanceWarmFluorescent:
                        return "Warm fluorescent"
                    case CameraImageProcessing.WhiteBalanceVendor:
                        return "Vendor"
                    default:
                        return "Unknown"
                    }
                }

                label: "White balance mode"
                enabled: CameraConfigs.supportedWhiteBalanceModes.length > 0
                value: name(camera.imageProcessing.whiteBalanceMode)

                menu: ContextMenu {
                    Repeater {
                        model: CameraConfigs.supportedWhiteBalanceModes

                        MenuItem {

                            text: whiteBalanceMode.name(modelData)
                            onClicked: camera.imageProcessing.whiteBalanceMode = modelData
                        }
                    }
                }
            }

            Slider {
                visible: camera.imageProcessing.whiteBalanceMode === CameraImageProcessing.WhiteBalanceManual
                minimumValue: 2000
                maximumValue: 9000
                value: camera.imageProcessing.manualWhiteBalance
                label: "Manual white balance"
                valueText: camera.imageProcessing.manualWhiteBalance.toFixed(0)
                width: parent.width
                onValueChanged: camera.imageProcessing.manualWhiteBalance = value
            }

            ComboBox {
                id: colorFilter

                function name(filter) {
                    switch (filter) {
                    case CameraImageProcessing.ColorFilterNone:
                        return "None"
                    case CameraImageProcessing.ColorFilterGrayscale:
                        return "Grayscale"
                    case CameraImageProcessing.ColorFilterNegative:
                        return "Negative"
                    case CameraImageProcessing.ColorFilterSolarize:
                        return "Solarize"
                    case CameraImageProcessing.ColorFilterSepia:
                        return "Sepia"
                    case CameraImageProcessing.ColorFilterPosterize:
                        return "Posterize"
                    case CameraImageProcessing.ColorFilterWhiteboard:
                        return "Whiteboard"
                    case CameraImageProcessing.ColorFilterBlackboard:
                        return "Blackboard"
                    case CameraImageProcessing.ColorFilterAqua:
                        return "Aqua"
                    case CameraImageProcessing.ColorFilterEmboss:
                        return "Emboss"
                    case CameraImageProcessing.ColorFilterSketch:
                        return "Sketch"
                    case CameraImageProcessing.ColorFilterNeon:
                        return "Neon"
                    case CameraImageProcessing.ColorFilterVendor:
                        return "Vendor"
                    default:
                        return "Unknown"
                    }
                }
                label: "Color filter"
                value: name(camera.imageProcessing.colorFilter)
                menu: ContextMenu {
                    Repeater {
                        model: [CameraImageProcessing.ColorFilterNone, CameraImageProcessing.ColorFilterGrayscale, CameraImageProcessing.ColorFilterNegative, CameraImageProcessing.ColorFilterSolarize, CameraImageProcessing.ColorFilterSepia, CameraImageProcessing.ColorFilterPosterize, CameraImageProcessing.ColorFilterWhiteboard, CameraImageProcessing.ColorFilterBlackboard, CameraImageProcessing.ColorFilterAqua, CameraImageProcessing.ColorFilterEmboss, CameraImageProcessing.ColorFilterSketch, CameraImageProcessing.ColorFilterNeon, CameraImageProcessing.ColorFilterVendor]

                        MenuItem {
                            text: colorFilter.name(modelData)
                            onClicked: camera.imageProcessing.colorFilter = modelData
                        }
                    }
                }
            }

            /*
              Uncomment when works
            Slider {
                minimumValue: -1.0
                maximumValue: 1.0
                value: camera.imageProcessing.contrast
                label: "Contrast"
                valueText: camera.imageProcessing.contrast.toFixed(2)
                width: parent.width
                onValueChanged: camera.imageProcessing.contrast = value
            }

            Slider {
                minimumValue: -1.0
                maximumValue: 1.0
                value: camera.imageProcessing.denoisingLevel
                label: "Denoising level"
                valueText: camera.imageProcessing.denoisingLevel.toFixed(2)
                width: parent.width
                onValueChanged: camera.imageProcessing.denoisingLevel = value
            }

            Slider {
                minimumValue: -1.0
                maximumValue: 1.0
                value: camera.imageProcessing.saturation
                label: "Saturation"
                valueText: camera.imageProcessing.saturation.toFixed(2)
                width: parent.width
                onValueChanged: camera.imageProcessing.saturation = value
            }

            Slider {
                minimumValue: -1.0
                maximumValue: 1.0
                value: camera.imageProcessing.sharpeningLevel
                label: "Sharpening level"
                valueText: camera.imageProcessing.sharpeningLevel.toFixed(2)
                width: parent.width
                onValueChanged: camera.imageProcessing.sharpeningLevel = value
            }*/

            SectionHeader {
                text: "Metadata"
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                text: "Metadata is write-only API to define metadata baked into the captured photos and videos"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                wrapMode: Text.Wrap
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            TextField {
                label: "Manufacturer"
                onTextChanged: camera.metaData.cameraManufacturer = text
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: modelField.focus = true
            }

            TextField {
                id: modelField

                label: "Model"
                onTextChanged: camera.metaData.cameraModel = text

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: eventField.focus = true
            }

            TextField {
                id: eventField

                label: "Event"
                onTextChanged: camera.metaData.event = text

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: subjectField.focus = true
            }

            TextField {
                id: subjectField

                label: "Subject"
                onTextChanged: camera.metaData.subject = text

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: latitudeField.focus = true
            }

            ComboBox {
                id: orientationComboBox
                label: "Orientation"
                value: "Not defined"
                menu: ContextMenu {
                    Repeater {
                        model: [0, 90, 180, 270]

                        MenuItem {
                            text: modelData.toString()
                            onClicked: {
                                camera.metaData.orientation = modelData
                                orientationComboBox.value = modelData.toString()
                            }
                        }
                    }
                }
            }

            DetailItem {
                id: dateTimeOriginal
                label: "Date time original"
                value: "Not defined"
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            Button {
                text: "Update"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    var now = new Date()
                    camera.metaData.dateTimeOriginal = now
                    dateTimeOriginal.value = now
                }
            }

            SectionHeader {
                text: "Location metadata"
            }

            TextField {
                id: latitudeField

                label: "Latitude"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                text: camera.metaData.gpsLatitude ? camera.metaData.gpsLatitude : ""
                onTextChanged: camera.metaData.gpsLatitude = parseFloat(text)

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: longitudeField.focus = true
            }

            TextField {
                id: longitudeField

                label: "Longitude"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onTextChanged: camera.metaData.gpsLongitude = parseFloat(text)

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: altitudeField.focus = true
            }

            TextField {
                id: altitudeField

                label: "Altitude"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onTextChanged: camera.metaData.gpsAltitude = parseFloat(text)

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: speedField.focus = true
            }

            TextField {
                id: speedField

                label: "Speed"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onTextChanged: camera.metaData.gpsSpeed = parseFloat(text)

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: trackField.focus = true
            }

            DetailItem {
                id: gpsTimestamp
                label: "GPS timestamp"
                value: "Not defined"
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Update time"
                onClicked: {
                    var now = new Date
                    camera.metaData.gpsTimestamp = now
                    gpsTimestamp.value = now
                }
            }

            TextField {
                id: trackField

                label: "GPS track"
                description: "Measured in degrees clockwise from north"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onTextChanged: camera.metaData.gpsTrack = parseFloat(text)

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: imgeDirectionField.focus = true
            }

            TextField {
                id: imgeDirectionField

                label: "GPS image direction"
                description: "Direction the camera is facing at the time of capture"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                onTextChanged: camera.metaData.gpsImgDirection = parseFloat(text)

                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: processingMethodField.focus = true
            }

            TextField {
                id: processingMethodField
                label: "GPS processing method"
                description: "Method for determining the GPS position"
                onTextChanged: camera.metaData.gpsProcessingMethod = text

                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false
            }
        }
    }
}
