import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0

Item {
    width: parent.width
    height: parent.height

    property Item _applicationWindow: __silica_applicationwindow_instance

    GlassBackgroundBase {
        id: glassBackground


        backgroundItem: _applicationWindow && _applicationWindow._applicationBlur
        //	Homescreen values
        //        color: Theme.rgba(root.palette.overlayBackgroundColor, 0.65)
        color: Theme.rgba(Theme.overlayBackgroundColor, 0.65)
        anchors.fill: parent
        blending: true
    }

    OverlayBackground.source: _applicationWindow && _applicationWindow._overlayBackgroundSource
    OverlayBackground.capture: parent && visible

    IconGridViewBase {
        id: grid

        y: launcherLayout.topMargin
        height: parent.height
        model: ["phone", "messaging", "browser", "camera", "people",
            "store", "gallery", "settings", "tutorial", "calendar",
            "weather", "clock", "email", "mediaplayer", "office",
            "notes", "calculator", "shell"]

        VerticalScrollDecorator {}
        delegate: BackgroundItem {
            width: grid.cellWidth
            height: grid.cellHeight
            enabled: false
            highlightedColor: Theme.rgba(palette.highlightColor, Theme.highlightBackgroundOpacity)
            Column {
                spacing: Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                HighlightImage {
                    source: "image://theme/icon-launcher-" + modelData
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Label {
                    width: parent.width - 2 * Theme.paddingMedium
                    anchors.horizontalCenter: parent.horizontalCenter
                    horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                    truncationMode: TruncationMode.Fade

                    font {
                        pixelSize: Theme.fontSizeTiny
                        capitalization: Font.Capitalize
                    }
                    text: modelData.replace("-", " ")
                }
            }
        }
    }

    Image {
        source: "image://theme/graphic-edge-swipe-handle-top"
        anchors {
            bottom: parent.top
            horizontalCenter: applicationGrid.horizontalCenter
        }
    }

    Image {
        source: "image://theme/graphic-edge-swipe-handle-bottom"

        anchors {
            horizontalCenter: applicationGrid.horizontalCenter
        }
    }
}
