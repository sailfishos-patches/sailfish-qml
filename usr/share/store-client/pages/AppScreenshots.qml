import QtQuick 2.0
import Sailfish.Silica 1.0

Row {
    id: root

    property alias urls: repeater.model

    width: Math.min(parent.width, urls.length * parent.width/3)
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Math.round(Theme.pixelRatio)

    Repeater {
        id: repeater

        // keep track of the images that have finished loading, as the UI
        // design proposes loading sequentially from left to right, showing
        // a spinner on the image that is currently loading
        property int loadingOffset

        delegate: StoreImage {
            id: img

            fillMode: Image.PreserveAspectFit
            image: (index > repeater.loadingOffset) ? "" : modelData
            width: (root.parent.width - 2*root.spacing)/3
            sourceSize.width: width

            onImageStatusChanged: {
                if (image && imageStatus !== Image.Loading) {
                    // advance to the next image, if the image stopped
                    // loading (has loaded or failed)
                    repeater.loadingOffset = Math.max(repeater.loadingOffset, index + 1)
                }
            }

            BusyIndicator {
                y: parent.width/2 - height/2
                anchors.horizontalCenter: parent.horizontalCenter
                running: img.imageStatus === Image.Loading
            }

            Rectangle {
                anchors.fill: parent
                visible: mouse.pressed && mouse.containsMouse
                color: Theme.highlightBackgroundColor
                opacity: Theme.highlightBackgroundOpacity
            }

            MouseArea {
                id: mouse
                anchors.fill: parent

                onClicked: {
                    if (!jollaStore.isOnline) {
                        jollaStore.tryGoOnline()
                    } else {
                        var props = { "model": root.urls, "currentIndex": model.index }
                        pageStack.push(Qt.resolvedUrl("ScreenshotPage.qml"), props)
                    }
                }
            }
        }
    }
}
