import QtQuick 2.1
import QtDocGallery 5.0
import Sailfish.Silica 1.0
import com.jolla.camera 1.0

GalleryView {
    id: root

    property bool populated
    captureModel: CaptureModel {
        source: DocumentGalleryModel {
            id: galleryModel

            rootType: DocumentGallery.File
            properties: [ "url", "mimeType", "orientation", "duration", "width", "height" ]
            sortProperties: ["lastModified"]
            autoUpdate: true
            filter: GalleryFilterUnion {
                GalleryEqualsFilter { property: "path"; value: Settings.photoDirectory }
                GalleryEqualsFilter { property: "path"; value: Settings.videoDirectory }
            }
            onStatusChanged: {
                if (status === DocumentGalleryModel.Finished
                        || status === DocumentGalleryModel.Canceled
                        || status === DocumentGalleryModel.Error) {
                    root.populated = true
                    _positionViewAtBeginning()
                }
            }
        }
    }

    ViewPlaceholder {
        //: Placeholder text for an empty camera reel view
        //% "Captured photos and videos will appear here when you take some"
        text: qsTrId("camera-la-no-photos")
        enabled: root.count === 0 && root.populated
    }
}
