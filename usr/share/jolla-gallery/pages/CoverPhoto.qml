import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.thumbnailer 1.0

Item {
    id: photo
    property alias source: thumbnail.source
    property alias mimeType: thumbnail.mimeType

    property real borderWidth: Theme.paddingMedium

    property real offsetX
    property real offsetY
    property real photoScale: 1.0
    property alias priority: thumbnail.priority
    property real photoSize: Math.min(width, height-borderWidth)

    Item {
        anchors {
            centerIn: parent
            horizontalCenterOffset: offsetX
            verticalCenterOffset: offsetY
        }

        // 1.414 is the ratio of a square diagonal::side
        width: photoSize * 1.414
        height: (photoSize + borderWidth) * 1.414
        scale: photoScale

        layer.enabled: parent.opacity != 1.0
        layer.smooth: true

        Item {
            clip: true
            anchors.fill: thumbnail
            Rectangle {
                anchors {
                    fill: parent
                    margins: -parent.width * 0.2
                }
                rotation: -30
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#404040" }
                    GradientStop { position: 1.0; color: "#999999" }
                }
            }
        }

        Thumbnail {
            id: thumbnail
            anchors {
                centerIn: parent
                verticalCenterOffset: -borderWidth/2
            }
            width: photoSize - borderWidth
            height: photoSize - borderWidth
            sourceSize.width: width * 1.5
            sourceSize.height: height * 1.5
            fillMode: Image.PreserveAspectCrop
            opacity: status == Thumbnail.Ready ? 1.0 : 0.0
            Behavior on opacity {
                id: developAnim
                enabled: false
                FadeAnimator { duration: 3000 }
            }
            Timer {
                // If the thumbnail is not immediately available, fade it in slowly when ready
                running: true
                interval: 50
                onTriggered: developAnim.enabled = true
            }
        }
        Image {
            source: "image://theme/graphic-gallery-frame?#FFFFFF"
            anchors.centerIn: parent
            width: photoSize
            height: photoSize + borderWidth
            sourceSize.width: photo.width*1.5
            smooth: true
        }
    }
}
