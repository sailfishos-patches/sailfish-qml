/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */
 import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
import Sailfish.Policy 1.0
import com.jolla.camera 1.0
import QtMultimedia 5.4
import Nemo.KeepAlive 1.2
import com.jolla.settings.system 1.0
import "capture"
import "gallery"

Page {
    id: page

    property alias viewfinder: captureView.viewfinder
    property bool galleryActive
    property url galleryView
    readonly property bool captureModeActive: switcherView.currentIndex === 1
    readonly property bool galleryVisible: galleryLoader.visible
    readonly property int galleryIndex: galleryLoader.item ? galleryLoader.item.currentIndex : 0
    readonly property QtObject captureModel: galleryLoader.item ? galleryLoader.item.captureModel : null

    function returnToCaptureMode() {
        switcherView.returnToCaptureMode()
    }

    palette.colorScheme: Theme.LightOnDark

    _opaqueBackground: true

    allowedOrientations: captureView.inButtonLayout ? page.orientation : Orientation.All


    Item {
        parent: page.parent

        width: page.width
        height: page.height
        rotation: page.rotation

        anchors.centerIn: parent
        z: -1

        Rectangle {
            x: galleryItem.x
            y: galleryItem.y
            width: galleryItem.width
            height: galleryItem.height
            color: "black"
            visible: galleryItem.PagedView.exposed
        }
    }

    PagedView {
        id: switcherView

        readonly property bool transitioning: moving || returnToCaptureModeTimeout.running

        function returnToCaptureMode() {
            if (Qt.application.active) {
                if (pageStack.currentPage === page) {
                    returnToCaptureModeTimeout.restart()
                    switcherView.currentIndex = 1
                }
            } else {
                pageStack.pop(page, PageStackAction.Immediate)
                moveTo(1, PagedView.Immediate)
            }
        }

        Timer {
            id: returnToCaptureModeTimeout
            interval: 300 //switcherView.highlightMoveDuration
        }

        width: page.width
        height: page.height
        wrapMode: PagedView.NoWrap

        interactive: (!galleryLoader.item || !galleryLoader.item.positionLocked)
                     && !captureView.recording
        currentIndex: 1
        focus: true

        Keys.onPressed: {
            if (!event.isAutoRepeat && event.key == Qt.Key_Camera) {
                switcherView.returnToCaptureMode()
            }
        }

        model: VisualItemModel {
            Item {
                id: galleryItem

                width: page.width
                height: page.height

                Loader {
                    id: galleryLoader

                    anchors.fill: parent

                    asynchronous: true
                    visible: switcherView.moving || page.galleryActive || returnToCaptureModeTimeout.running
                }

                BusyIndicator {
                    anchors.centerIn: parent
                    size: BusyIndicatorSize.Large
                    running: galleryLoader.status == Loader.Loading
                }
            }

            CaptureView {
                id: captureView

                readonly property real _viewfinderPosition: orientation == Orientation.Portrait || orientation == Orientation.Landscape
                                                            ? parent.x + x
                                                            : -parent.x - x
                width: page.width
                height: page.height

                active: true

                orientation: page.orientation
                pageRotation: page.rotation
                captureModel: page.captureModel
                orientationTransitionRunning: page.orientationTransitionRunning

                visible: switcherView.moving || captureView.active

                onLoaded: {
                    if (galleryLoader.source == "") {
                        galleryLoader.setSource(galleryView, { page: page })
                    }
                }

                CameraRollHint { z: 2 }
                CameraModeHint { z: 2 }

                Binding {
                    target: captureView.viewfinder
                    property: "x"
                    value: captureView.isPortrait
                           ? captureView._viewfinderPosition
                           : 0
                }

                Binding {
                    target: captureView.viewfinder
                    property: "y"
                    value: !captureView.isPortrait
                           ? captureView._viewfinderPosition + (page.orientation == Orientation.Landscape
                                                                ? captureView.viewfinderOffset : -captureView.viewfinderOffset)
                           : (page.orientation == Orientation.Portrait ? captureView.viewfinderOffset
                                                                       : -captureView.viewfinderOffset)
                }
            }
        }

        onCurrentItemChanged: {
            if (!transitioning) {
                page.galleryActive = galleryItem.PagedView.isCurrentItem
                captureView.active = captureView.PagedView.isCurrentItem
            }
        }

        onTransitioningChanged: {
            if (!transitioning) {
                page.galleryActive = galleryItem.PagedView.isCurrentItem
                captureView.active = captureView.PagedView.isCurrentItem
            } else if (captureView.active) {
                if (galleryLoader.source == "") {
                    galleryLoader.setSource("gallery/GalleryView.qml", { page: page })
                } else if (galleryLoader.item) {
                    galleryLoader.item._positionViewAtBeginning()
                }
            }
        }
    }


    DisabledByMdmView {
        //% "Camera"
        activity: qsTrId("sailfish_browser-la-camera");
        enabled: !AccessPolicy.cameraEnabled
    }

    DisplayBlanking {
        preventBlanking: (galleryLoader.item && galleryLoader.item.playing)
                         || captureView.camera.videoRecorder.recorderState == CameraRecorder.RecordingState
    }
}
