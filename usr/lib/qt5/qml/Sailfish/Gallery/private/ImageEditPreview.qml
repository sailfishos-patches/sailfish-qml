/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Raine Mäkeläinen <raine.makelainen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0
import Sailfish.Gallery.private 1.0

Item {
    id: root

    // Uncomment to debug
    // FlickableDebugItem { Component.onCompleted: titleLabel.text = "" }

    property bool cropOnly

    // Aspect ratio as width / height
    property real aspectRatio: -1.0
    property string aspectRatioType: "none"

    property bool isPortrait: width < height
    property bool active
    property bool editInProgress
    property alias source: zoomableImage.source
    property alias target: editor.target
    property int previewRotation: zoomableImage.imageRotation
    property alias previewBrightness: zoomableImage.brightness
    property alias previewContrast: zoomableImage.contrast
    property alias animatingBrightnessContrast: zoomableImage.animatingBrightnessContrast
    readonly property alias longPressed: zoomableImage.longPressed

    signal edited
    signal failed

    clip: true

    function crop() {
        editInProgress = true
        var cropSize = Qt.size(editor.width, editor.height)

        var transpose = (zoomableImage.baseRotation % 180) != 0

        var imageWidth = transpose ? zoomableImage.photo.height : zoomableImage.photo.width

        var imageHeight = transpose ? zoomableImage.photo.width : zoomableImage.photo.height

        var imageSize = Qt.size(imageWidth, imageHeight)
        var position = Qt.point(
                    zoomableImage.contentX + zoomableImage.leftMargin,
                    zoomableImage.contentY + zoomableImage.topMargin)

        editor.crop(cropSize, imageSize, position)
    }

    function rotateImage() {
        editInProgress = true
        editor.rotate(zoomableImage.imageRotation)
    }

    function adjustLevels() {
        editInProgress = true
        editor.adjustLevels(root.previewBrightness, root.previewContrast)
    }

    function resetZoom() {
        editor.setSize()
        zoomableImage.resetZoom()
    }

    function previewRotate(angle) {
        zoomableImage.rotate(angle)
        editor.setSize()
    }

    onAspectRatioTypeChanged: resetZoom()

    onIsPortraitChanged: {
        // Reset back to original aspect ratio that needs to be calculated
        if (aspectRatioType == "original") {
            aspectRatio = -1.0
        }

        delayedReset.restart()
    }

    // ImageMetadata is needed to track the real orientation
    // when the file is being edited.
    ImageMetadata {
        id: metadata
        source: root.source
    }

    ZoomableImage {
        id: zoomableImage

        minimumContentWidth: width - (isPortrait ? Theme.itemSizeMedium : Theme.itemSizeSmall)
        minimumContentHeight: height - (isPortrait ? Theme.itemSizeSmall : Theme.itemSizeMedium)

        anchors.fill: parent
        baseRotation: -metadata.orientation
        photo.onStatusChanged: if (photo.status === Image.Ready) delayedReset.restart()
    }

    Timer {
        id: delayedReset
        running: true; interval: 10
        onTriggered: root.resetZoom()
    }

    ImageEditor {
        id : editor

        anchors.centerIn: parent
        source: zoomableImage.source

        function reset() {
            zoomableImage.leftMargin = 0
            zoomableImage.rightMargin = 0
            zoomableImage.topMargin = 0
            zoomableImage.bottomMargin = 0
            zoomableImage.minimumZoom = zoomableImage.implicitFittedZoom
            zoomableImage.fittedZoom = zoomableImage.implicitFittedZoom
            zoomableImage.resetZoom()
        }

        // As a function to avoid binding loops
        function setSize() {
            if (root.width === 0 || root.height == 0 ) return

            reset()
            var realAspectRatio = !zoomableImage.transpose
                    ? metadata.width / metadata.height
                    : metadata.height / metadata.width

            if (aspectRatio === -1.0) {
                return
            } else if (aspectRatio === 0.0) {
                aspectRatio = realAspectRatio
            }
            var maxWidth = zoomableImage.minimumContentWidth
            var maxHeight = zoomableImage.minimumContentHeight
            if (isPortrait) {
                var tmpHeight = maxWidth / aspectRatio
                if (tmpHeight > maxHeight) {
                    maxWidth = maxHeight * aspectRatio
                }

                width = maxWidth
                height = Math.round(width / aspectRatio)
            } else {
                var tmpWidth = aspectRatio * maxHeight
                if (tmpWidth > maxWidth) {
                    maxHeight = maxWidth / aspectRatio
                }
                height = maxHeight
                width =  Math.round(aspectRatio * height)
            }

            zoomableImage.leftMargin = Qt.binding( function () {
                var photoSize = zoomableImage.transpose ? zoomableImage.photo.height : zoomableImage.photo.width
                var margin = (Math.min(photoSize, root.width) - editor.width)/2
                if (zoomableImage.contentWidth < root.width) {
                    margin = margin + (root.width - zoomableImage.contentWidth)/2
                }
                return margin
            })
            zoomableImage.rightMargin = Qt.binding( function () { return zoomableImage.leftMargin } )
            zoomableImage.topMargin = Qt.binding( function () {
                var photoSize = zoomableImage.transpose ? zoomableImage.photo.width : zoomableImage.photo.height
                var margin = (Math.min(photoSize, root.height) - editor.height)/2

                if (zoomableImage.contentHeight < root.height) {
                    margin = margin + (root.height - zoomableImage.contentHeight)/2
                }
                return margin
            })
            zoomableImage.bottomMargin = Qt.binding( function () { return zoomableImage.topMargin })

            var contentHeight = Math.min(zoomableImage.transpose ? zoomableImage.photo.width : zoomableImage.photo.height, root.height)
            var contentWidth = Math.min(zoomableImage.transpose ? zoomableImage.photo.height : zoomableImage.photo.width, root.width)

            zoomableImage.minimumZoom = zoomableImage.zoom * Math.max(height/contentHeight, width/contentWidth)
            if (realAspectRatio !== aspectRatio) {
                zoomableImage.fittedZoom = zoomableImage.minimumZoom
            }

            zoomableImage.resetZoom()
        }

        onCropped: {
            editInProgress = false
            if (success) {
                root.source = target
                root.edited()
            } else {
                root.failed()
            }
        }

        onRotated: {
            editInProgress = false
            root.previewRotation = 0
            if (success) {
                root.source = target
                root.edited()
            } else {
                console.log("Failed to rotate image!")
                root.failed()
            }
        }

        onLevelsAdjusted: {
            editInProgress = false
            root.previewBrightness = 0.0
            root.previewContrast = 0.0
            if (success) {
                root.source = target
                root.edited()
            } else {
                console.log("Failed to adjust image levels!")
                root.failed()
            }
        }
    }

    DimmedRegion {
        anchors.fill: parent
        color: Theme.highlightDimmerFromColor(Theme.highlightDimmerColor, Theme.LightOnDark)
        opacity: aspectRatioType !== "none" ? Theme.opacityHigh : 0.0
        visible: !longPressed


        target: root
        area: Qt.rect(0, 0, root.width, root.height)
        exclude: [ editor ]
        z: 1

        Behavior on opacity { FadeAnimator {} }
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: editInProgress
    }
}
