import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Thumbnailer 1.0

/*!
  \inqmlmodule Sailfish.Gallery
*/
ThumbnailBase {
    id: thumbnailBase

    readonly property alias status: thumbnail.status
    /*!
      \internal
    */
    property alias _thumbnail: thumbnail

    Image {
        anchors.fill: parent
        source: thumbnail.status === Thumbnail.Ready ? ""
                                                     : "image://theme/graphic-grid-item-background"
    }

    Thumbnail {
        id: thumbnail
        property bool gridMoving: thumbnailBase.grid ? thumbnailBase.grid.moving : false

        source: thumbnailBase.source
        mimeType: thumbnailBase.mimeType
        width: thumbnailBase.width
        height: thumbnailBase.contentHeight
        sourceSize.width: width
        sourceSize.height: height
        priority: Thumbnail.NormalPriority

        onGridMovingChanged: {
            if (!gridMoving) {
                var visibleIndex = Math.floor(thumbnailBase.grid.contentY / thumbnailBase.contentHeight) * thumbnailBase.grid.columnCount

                if (visibleIndex <= index && index <= visibleIndex + 18) {
                    priority = Thumbnail.HighPriority
                } else {
                    priority = Thumbnail.LowPriority
                }
            }
        }

        onStatusChanged: {
            if (status == Thumbnail.Error) {
                errorLabelComponent.createObject(thumbnail)
            }
        }
    }

    Component {
        id: errorLabelComponent
        Label {
            //: Thumbnail Image loading failed
            //% "Oops, can't display the thumbnail!"
            text: qsTrId("components_gallery-la-image-thumbnail-loading-failed")
            anchors.centerIn: parent
            width: parent.width - 2 * Theme.paddingMedium
            height: parent.height - 2 * Theme.paddingSmall
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Theme.fontSizeSmall
            fontSizeMode: Text.Fit
            opacity: thumbnail.status == Thumbnail.Error ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {}}
        }
    }
}
