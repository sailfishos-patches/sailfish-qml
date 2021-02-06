import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0
import Sailfish.Silica.private 1.0

Item {
    property alias backgroundItem: backgroundSource.sourceItem

    width: parent.width
    height: parent.height

    ShaderEffectSource {
        id: backgroundSource
        visible: false
        sourceItem: background

        live: false
    }

    ThemeWallpaper {
        id: blur

        visible: false

        sourceItem: backgroundSource
    }

    ThemeBackground {
        width: parent.width
        height: parent.height

        sourceItem: blur
    }

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
