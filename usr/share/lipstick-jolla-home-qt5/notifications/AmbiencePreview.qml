import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Ambience 1.0
import org.nemomobile.lipstick 0.1

Item {
    id: ambiencePreview
    property alias displayName: displayNameLabel.text
    property alias coverImage: image.source

    signal finished

    width: 4 * Theme.itemSizeExtraLarge
    height: Screen.sizeCategory >= Screen.Large
        ? Theme.itemSizeExtraLarge + (2 * Theme.paddingLarge)
        : Screen.height / 5
    visible: peekAnimation.running
    y: -height

    property bool _pending
    property bool _topMenuExposed: Lipstick.compositor.topMenuLayer.exposed

    function show() {
        _pending = false
        if (image.status === Image.Ready) {
            peekAnimation.restart()
        } else if (image.status === Image.Loading) {
            _pending = true
        } else {
            finished()
        }
    }

    on_TopMenuExposedChanged: {
        if (peekAnimation.running && _topMenuExposed) {
            peekAnimation.stop()
        }
    }

    SequentialAnimation {
        id: peekAnimation
        alwaysRunToEnd: true

        NumberAnimation {
            target: ambiencePreview
            property: "y"
            from: -height
            to: 0
            duration: 300
            easing.type: Easing.OutQuad
        }
        PauseAnimation {
            duration: 2000
        }
        NumberAnimation {
            target: ambiencePreview
            property: "y"
            from: 0
            to: -height
            duration: 300
            easing.type: Easing.InQuad
        }
        ScriptAction {
            script: finished()
        }
    }

    Image {
        id: image
        anchors.fill: parent
        clip: true
        fillMode: Image.PreserveAspectCrop
        sourceSize { width: width; height: height }
        smooth: true
        asynchronous: true

        onStatusChanged: {
            if (_pending) {
                if (status === Image.Ready) {
                    _pending = false
                    peekAnimation.restart()
                } else if (status === Image.Error || status === Image.Null) {
                    _pending = false
                    finished()
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.rgba(Theme.highlightDimmerColor, Theme.opacityHigh)
        }

        BusyIndicator {
            anchors.centerIn: parent
            size: BusyIndicatorSize.Medium
            running: true
        }
    }

    Label {
        id: displayNameLabel
        anchors {
            left: parent.left
            leftMargin: Theme.paddingLarge
            right: parent.right
            rightMargin: Theme.paddingLarge
            bottom: parent.bottom
            bottomMargin: Theme.paddingMedium
        }
        font.pixelSize: Theme.fontSizeLarge
        horizontalAlignment: Text.AlignLeft
        wrapMode: Text.Wrap
        maximumLineCount: 2
        truncationMode: TruncationMode.Elide
        color: Theme.highlightColor
    }
}
