/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import QtMultimedia 5.5
import QtDocGallery 5.0
import org.nemomobile.systemsettings 1.0
import ".."

CsdTestPage {
    id: page

    property bool shouldShowControls: true

    readonly property bool controlsVisible: shouldShowControls && !video.loading
    property bool firstVideoLoaded
    property int totalPlayTime
    property int minimumPlayingTime: runInTests
                                     ? page.parameters["RunInTestTime"] * 60*1000 : 15000


    allowedOrientations: firstVideoLoaded ? ((video.contentRect.height > video.contentRect.width) ?
                                                 Orientation.Portrait : Orientation.Landscape) :
                                            Orientation.Portrait
    orientation: allowedOrientations

    property bool originalAmbientLightSensor
    property int originalBrightness

    Component.onDestruction: {
        // Restore original values.
        displaySettings.ambientLightSensorEnabled = originalAmbientLightSensor
        displaySettings.brightness = originalBrightness
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            video.tryNext()
        }
    }

    VideoPlayer {
        id: video

        readonly property bool loading: (video.status === MediaPlayer.Loading) && firstVideoLoaded
        property bool atLastUrl: videoIndex === videosModel.count - 1
        property int videoIndex: -1
        property int lastPosition

        function tryNext() {
            if (videosModel.status != DocumentGalleryModel.Finished
                    && videosModel.status != DocumentGalleryModel.Error) {
                tryNextTimer.start()
                return
            }
            if (videosModel.count == 0 || atLastUrl) {
                console.log("CSD VideoPlayback failure, video count: ", videosModel.count, "or at last url:", atLastUrl)
                setTestResult(false)
                testCompleted(true)
            } else {
                videoIndex += 1
                source = videosModel.get(videoIndex).url
            }
        }

        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
        opacity: !video.loading ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }

        loops: MediaPlayer.Infinite

        onErrorChanged: {
            if (atLastUrl && error !== MediaPlayer.NoError) {
                console.log("CSD VideoPlayback failure, error code: ", error)
                setTestResult(false)
                testCompleted(true)
            }
        }

        onAvailabilityChanged: {
            if (availability !== MediaPlayer.Available) {
                console.log("CSD VideoPlayback failure no available: ", availability)
                setTestResult(false)
                testCompleted(true)
            }
        }

        onPositionChanged: {
            if (position > 0) {
                totalPlayTime += (position - lastPosition)
            }
            lastPosition = position
            if (totalPlayTime >= minimumPlayingTime) {
                setTestResult(true)
                testCompleted(true)
            }
        }

        onStatusChanged: {
            switch (status) {
            case MediaPlayer.Loaded:
                firstVideoLoaded = true
                play()
                break
            case MediaPlayer.EndOfMedia:
                // loop until we've played for the minimumPlayingTime
                if (runInTests) {
                    console.log("CSD Video playback ended, video duration: ", video.duration)
                    setTestResult(true)
                }
                break
            case MediaPlayer.InvalidMedia:
                tryNextTimer.start()
                break
            default:
            }
        }
    }

    CsdPageHeader {
        id: header
        //% "Video playback"
        title: qsTrId("csd-he-video_playback")
        opacity: !video.loading ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: shouldShowControls = !shouldShowControls
    }

    DimmerBackground {
        id: videoStatusBackground

        enabled: controlsVisible
        anchors {
            top: header.bottom
            topMargin: Theme.paddingMedium
        }
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * x
        contentHeight: videoStatus.height

        Column {
            id: videoStatus
            width: videoStatusBackground.width

            Label {
                width: parent.width

                //% "Status: %1"
                text: qsTrId("csd-la-video_status").arg(statusToString(video.status))

                function statusToString(status) {
                    switch (status) {
                    case MediaPlayer.NoMedia:
                        //% "No media has been set"
                        return qsTrId("csd-la-video_status_no_media")
                    case MediaPlayer.Loading:
                        //% "Loading media"
                        return qsTrId("csd-la-video_status_loading_media")
                    case MediaPlayer.Loaded:
                        //% "Media loaded"
                        return qsTrId("csd-la-video_media_loaded")
                    case MediaPlayer.Buffering:
                        //% "Buffering media"
                        return qsTrId("csd-la-video_buffering_media")
                    case MediaPlayer.Stalled:
                        //% "Buffering stalled"
                        return qsTrId("csd-la-video_media_stalled")
                    case MediaPlayer.Buffered:
                        //% "Media buffered"
                        return qsTrId("csd-la-video_media_buffered")
                    case MediaPlayer.EndOfMedia:
                        //% "Reached end of media"
                        return qsTrId("csd-la-video_end_of_media")
                    case MediaPlayer.InvalidMedia:
                        //% "Invalid media"
                        return qsTrId("csd-la-video_invalid_media")
                    case MediaPlayer.UnknownStatus:
                        //% "Unknown"
                        return qsTrId("csd-la-video_status_unknown")
                    }
                }
            }

            ProgressBar {
                width: parent.width

                maximumValue: video.duration
                value: video.position
            }
        }
    }

    DocumentGalleryModel {
        id: videosModel

        rootType: DocumentGallery.Video
        properties: ["url"]
    }

    DimmerBackground {
        id: videoInfoBackground
        enabled: controlsVisible
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * x
        contentHeight: videoInfo.height

        anchors {
            bottom: passFailButtons.visible ? passFailContainer.top : parent.bottom
            bottomMargin: passFailButtons.visible ? Theme.itemSizeSmall : Theme.paddingLarge
        }
        contentWidth: width

        Column {
            id: videoInfo

            spacing: Theme.paddingMedium
            width: videoInfoBackground.width

            Label {
                id: urlLabel
                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                text: {
                    if (videosModel.status != DocumentGalleryModel.Finished) {
                        if (videosModel.status == DocumentGalleryModel.Error) {
                            //% "Error while searching for video media!"
                            return qsTrId("csd-la-video_search_error")
                        } else {
                            //% "Searching for video media..."
                            return qsTrId("csd-la-video_searching_for_media")
                        }
                    }
                    videosModel.count == 0 && videosModel.status == DocumentGalleryModel.Finished
                          //% "Error: cannot find any video media!"
                        ? qsTrId("csd-la-video_cannot_find_media")
                        : video.source
                }
            }

            Label {
                width: parent.width
                //: Countdown to when the test will automatically be passed
                //% "Auto-passing in %n seconds"
                text: qsTrId("csd-la-test_auto_pass_countdown", Math.round((minimumPlayingTime - totalPlayTime) / 1000))
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                visible: !runInTests
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !runInTests && video.videoIndex < videosModel.count-1
                text: video.status == MediaPlayer.NoMedia
                        //% "Start"
                      ? qsTrId("csd-la-start")
                        //% "Next video"
                      : qsTrId("csd-la-next_video")

                onClicked: video.tryNext()
            }
        }
    }

    DimmerBackground {
        id: passFailContainer
        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
        }
        visible: !runInTests
        enabled: controlsVisible
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * x
        contentWidth: width
        contentHeight: passFailButtons.height

        ButtonLayout {
            id: passFailButtons

            rowSpacing: Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter

            PassButton {
                id: passButton
                onClicked: {
                    setTestResult(true)
                    testCompleted(true)
                }
            }
            FailButton {
                id: failButton
                onClicked: {
                    setTestResult(false)
                    testCompleted(true)
                }
            }
        }
    }

    Timer {
        id: tryNextTimer

        interval: 1000
        onTriggered: video.tryNext()
    }

    DisplaySettings {
        id: displaySettings
        onPopulatedChanged: {
            // Save existing backlight settings
            originalAmbientLightSensor = displaySettings.ambientLightSensorEnabled
            originalBrightness = displaySettings.brightness
            // Max out the brightness before test
            displaySettings.brightness = displaySettings.maximumBrightness
            // Also disable the ambient light sensor.
            displaySettings.ambientLightSensorEnabled = false
        }
    }
}
