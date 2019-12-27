import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

Item {
    id: splash

    property bool isPortrait

    // Positioning duplicated from Camera.  This should be shared in some fashion, but
    // preferably not by having lipstick import almost the entirety of camera.
    property list<Item> _buttonAnchors
    _buttonAnchors: [
        buttonAnchorTL,
        buttonAnchorCL,
        buttonAnchorBL,
        buttonAnchorBC,
        buttonAnchorBR,
        buttonAnchorCR,
        buttonAnchorTR
    ]

    // Position of other elements given the capture button position
    property var _portraitPositions: [
        { "captureMode": overlayAnchorBL, "cameraDevice": overlayAnchorBR }, // buttonAnchorTL
        { "captureMode": overlayAnchorBL, "cameraDevice": overlayAnchorBR }, // buttonAnchorCL
        { "captureMode": overlayAnchorBR, "cameraDevice": overlayAnchorBC }, // buttonAnchorBL
        { "captureMode": overlayAnchorBL, "cameraDevice": overlayAnchorBR }, // buttonAnchorBC
        { "captureMode": overlayAnchorBL, "cameraDevice": overlayAnchorBC }, // buttonAnchorBR
        { "captureMode": overlayAnchorBL, "cameraDevice": overlayAnchorBR }, // buttonAnchorCR
        { "captureMode": overlayAnchorBL, "cameraDevice": overlayAnchorBR }, // buttonAnchorTR
    ]
    property var _landscapePositions: [
        { "captureMode": overlayAnchorBL, "cameraDevice": overlayAnchorCL }, // buttonAnchorTL
        { "captureMode": overlayAnchorBL, "cameraDevice": overlayAnchorTL }, // buttonAnchorCL
        { "captureMode": overlayAnchorCL, "cameraDevice": overlayAnchorTL }, // buttonAnchorBL
        { "captureMode": overlayAnchorBL, "cameraDevice": overlayAnchorTL }, // buttonAnchorBC
        { "captureMode": overlayAnchorCR, "cameraDevice": overlayAnchorBC }, // buttonAnchorBR
        { "captureMode": overlayAnchorBR, "cameraDevice": overlayAnchorTR }, // buttonAnchorCR
        { "captureMode": overlayAnchorBR, "cameraDevice": overlayAnchorCR }, // buttonAnchorTR
    ]

    property var _overlayPosition: splash.isPortrait
            ? _portraitPositions[splash._captureButtonLocation]
            : _landscapePositions[splash._captureButtonLocation]

    readonly property int _captureButtonLocation: isPortrait
                ? globalSettings.portraitCaptureButtonLocation
                : globalSettings.landscapeCaptureButtonLocation

    ConfigurationGroup {
        id: globalSettings

        path: "/apps/jolla-camera"

        property string cameraDevice: "primary"
        property string captureMode: "image"

        property int portraitCaptureButtonLocation: 3
        property int landscapeCaptureButtonLocation: 4
    }

    // Shutter
    Item {
        parent: splash._buttonAnchors[splash._captureButtonLocation]

        anchors.centerIn: parent

        Rectangle {

            radius: Theme.itemSizeSmall / 2
            width: Theme.itemSizeSmall
            height: Theme.itemSizeSmall

            anchors.centerIn: parent

            opacity: Theme.opacityHigh
            color: Theme.highlightDimmerColor
        }

        BusyIndicator {
            anchors.centerIn: parent
            color: Theme.lightPrimaryColor
            size: BusyIndicatorSize.Large
            running: splash.visible
        }

        Image {
            id: image
            anchors.centerIn: parent
            scale: 1.5 // TODO: Need larger capture icon instead of scaling

            source: globalSettings.captureMode == "image"
                    ? "image://theme/icon-camera-shutter-release?" + Theme.lightPrimaryColor
                    : "image://theme/icon-m-call-recording-on?" + Theme.lightPrimaryColor
        }
    }

    Item {
        parent: splash._overlayPosition.captureMode

        width: Theme.itemSizeExtraSmall
        height: Theme.itemSizeExtraSmall

        anchors.centerIn: parent

        Rectangle {
            y: captureModeColumn.y + (globalSettings.captureMode == "image"
                    ? stillCaptureIcon.y
                    : videoCaptureIcon.y)

            width: Theme.itemSizeExtraSmall
            height: Theme.itemSizeExtraSmall

            radius: width / 2

            color: Theme.highlightColor
            opacity: Theme.opacityLow
        }

        Column {
            id: captureModeColumn

            y: (parent.height - height) / 2
            width: Theme.itemSizeExtraSmall
            spacing: Theme.paddingSmall

            Image {
                id: stillCaptureIcon

                width: Theme.itemSizeExtraSmall
                height: Theme.itemSizeExtraSmall

                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                fillMode: Image.Pad

                source: "image://theme/icon-camera-camera-mode?" + Theme.lightPrimaryColor
            }
            Image {
                id: videoCaptureIcon

                width: Theme.itemSizeExtraSmall
                height: Theme.itemSizeExtraSmall

                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                fillMode: Image.Pad

                source: "image://theme/icon-camera-video?" + Theme.lightPrimaryColor
            }

        }
    }

    ButtonAnchor { id: buttonAnchorTL; anchors { left: parent.left; top: parent.top } visible: !splash.isPortrait }
    ButtonAnchor { id: buttonAnchorCL; anchors { left: parent.left; verticalCenter: parent.verticalCenter } }
    ButtonAnchor { id: buttonAnchorBL; anchors { left: parent.left; bottom: parent.bottom } }
    ButtonAnchor { id: buttonAnchorBC; anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom } }
    ButtonAnchor { id: buttonAnchorBR; anchors { right: parent.right; bottom: parent.bottom } }
    ButtonAnchor { id: buttonAnchorCR; anchors { right: parent.right; verticalCenter: parent.verticalCenter } }
    ButtonAnchor { id: buttonAnchorTR; anchors { right: parent.right; top: parent.top } visible: !splash.isPortrait }

    OverlayAnchor { id: overlayAnchorBL; anchors { left: parent.left; bottom: parent.bottom } }
    OverlayAnchor { id: overlayAnchorBC; anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom } }
    OverlayAnchor { id: overlayAnchorBR; anchors { right: parent.right; bottom: parent.bottom } }
    OverlayAnchor { id: overlayAnchorCL; anchors { left: parent.left; verticalCenter: parent.verticalCenter } }
    OverlayAnchor { id: overlayAnchorCR; anchors { right: parent.right; verticalCenter: parent.verticalCenter } }
    OverlayAnchor { id: overlayAnchorTL; anchors { left: parent.left; top: parent.top} }
    OverlayAnchor { id: overlayAnchorTR; anchors { right: parent.right; top: parent.top } }
}
