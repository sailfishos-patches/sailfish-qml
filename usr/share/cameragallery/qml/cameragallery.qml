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

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.6
import CameraGallery 1.0
import Nemo.KeepAlive 1.2
import "pages"

ApplicationWindow {
    id: mainWindow

    background.color: "black"
    cover: Qt.resolvedUrl("cover/CameraTestCover.qml")
    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All

    initialPage: Component {
        Page {
            id: mainPage

            property bool pushAttached: status === PageStatus.Active
            onPushAttachedChanged: {
                pageStack.pushAttached(Qt.resolvedUrl("pages/SettingsPage.qml"), { 'camera': camera })
                pushAttached = false
            }

            DisplayBlanking {
                preventBlanking: camera.videoRecorder.recorderState == CameraRecorder.RecordingState
            }

            Binding {
                target: CameraConfigs
                property: "camera"
                value: camera
            }

            VideoOutput {
                id: videoOutput

                z: -1
                width: parent.width
                height: parent.height
                fillMode: VideoOutput.PreserveAspectFit
                source: Camera {
                    id: camera

                    imageCapture.onImageSaved: preview.source = path
                    videoRecorder {
                        frameRate: 30
                        audioChannels: 2
                        audioSampleRate: 48000
                        audioCodec: "audio/mpeg, mpegversion=(int)4"
                        audioEncodingMode: CameraRecorder.AverageBitRateEncoding
                        videoCodec: "video/x-h264"
                        mediaContainer: "video/quicktime, variant=(string)iso"
                        resolution: "1280x720"
                        videoBitRate: 12000000
                    }
                }

                // When another camera app is opened
                // the camera here goes to unloaded state.
                // Make sure the camera becomes active again
                Connections {
                    target: Qt.application
                    onActiveChanged: {
                        if (Qt.application.active) {
                            camera.cameraState = previousState
                        } else {
                            previousState = camera.cameraState
                        }
                    }
                    property int previousState: camera.cameraState
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (videoOutput.state == "miniature") {
                            pageStack.navigateBack()
                        } else {
                            pageStack.navigateForward()
                        }
                    }
                }

                states: State {
                    name: "miniature"
                    when: mainPage.status === PageStatus.Inactive || mainPage.status === PageStatus.Activating
                    PropertyChanges {
                        target: videoOutput
                        parent: pageStack
                        z: 1000
                        width: Theme.itemSizeExtraLarge
                        height: width
                        x: parent.width - width - Theme.paddingLarge
                        y: parent.height - height - Theme.paddingLarge
                    }
                }
            }

            PageHeader {
                z: 1
                title: "Camera settings"
                interactive: true
            }

            MouseArea {
                width: Theme.itemSizeExtraLarge
                height: Theme.itemSizeExtraLarge

                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: Theme.paddingLarge
                }

                onPressed: camera.searchAndLock()
                onReleased: {
                    if (camera.captureMode === Camera.CaptureVideo) {
                        if (camera.videoRecorder.recorderState == CameraRecorder.RecordingState) {
                            camera.videoRecorder.stop()
                        } else {
                            camera.videoRecorder.record()
                        }
                    } else {
                        if (containsMouse) {
                            camera.imageCapture.capture()
                        } else {
                            camera.unlock()
                        }
                    }
                }
                onCanceled: camera.unlockAutoFocus()

                Rectangle {
                    id: backgroundCircle

                    radius: width / 2
                    width: image.width
                    height: width

                    anchors.centerIn: parent

                    color: Theme.secondaryHighlightColor
                }

                Image {
                    id: image
                    anchors.centerIn: parent
                    source: camera.videoRecorder.recorderState == CameraRecorder.RecordingState
                            ? "image://theme/icon-camera-video-shutter-off"
                            : (camera.captureMode == Camera.CaptureVideo
                               ? "image://theme/icon-camera-video-shutter-on"
                               : "image://theme/icon-camera-shutter")
                }
            }

            MouseArea {

                onClicked: Qt.openUrlExternally(preview.source)

                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    margins: Theme.paddingLarge
                }

                width: Theme.itemSizeExtraLarge
                height: Theme.itemSizeExtraLarge
                opacity: containsMouse && pressed ? 0.6 : 1.0

                Image {
                    id: preview
                    z: -1
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                }
            }
        }
    }
}
