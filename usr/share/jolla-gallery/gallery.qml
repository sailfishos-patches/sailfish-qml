import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.gallery 1.0
import QtDocGallery 5.0
import "pages"

ApplicationWindow {
    id: window

    property alias photosModel: photosModel
    property alias videosModel: videosModel
    property var activeObject: ({url: "", mimeType: ""})
    property Page startPage

    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    DocumentGalleryModel {
        id: photosModel

        rootType: DocumentGallery.Image
        properties: ["url", "mimeType", "title", "orientation", "dateTaken", "width", "height" ]
        sortProperties: ["-dateTaken"]
        autoUpdate: true
        filter: GalleryFilterIntersection {
            GalleryStartsWithFilter { property: "filePath"; value: StandardPaths.music; negated: true }
            GalleryStartsWithFilter { property: "filePath"; value: StandardPaths.pictures + "/Screenshots/"; negated: true }
            GalleryStartsWithFilter { property: "filePath"; value: androidStorage.path; negated: true }
        }
    }

    DocumentGalleryModel {
        id: videosModel

        rootType: DocumentGallery.Video
        properties: ["url", "mimeType", "title", "lastModified", "orientation", "duration"]
        sortProperties: ["-lastModified"]
        autoUpdate: true
    }

    DocumentGalleryModel {
        id: screenshotsModel

        rootType: DocumentGallery.Image
        properties: ["url", "mimeType", "title", "orientation", "dateTaken", "width", "height" ]
        sortProperties: ["-dateTaken"]
        autoUpdate: true
        filter: GalleryStartsWithFilter { property: "filePath"; value: StandardPaths.pictures + "/Screenshots/" }
    }

    DocumentGalleryModel {
        id: androidStorage

        readonly property string path: StandardPaths.home + "/android_storage/"

        rootType: DocumentGallery.Image
        properties: ["url", "mimeType", "title", "orientation", "dateTaken", "width", "height" ]
        sortProperties: ["-dateTaken"]
        autoUpdate: true
        filter: GalleryStartsWithFilter { property: "filePath"; value: androidStorage.path }
    }

    // For some reason if the gallery is launched via invoker, it sets codecForLocale to
    // be ISO8859-1 instead of UTF-8 which causes the loading failure of the images using
    // Chinese characters. This can be used as a workaround for a bug: JB#11179.
    // NOTE: Setting codec in main.cpp doesn't seem to have any effect at all
    TextCodec { codecForLocale: "UTF-8" }

    cover: Qt.resolvedUrl("pages/GalleryCover.qml")

    initialPage: Component { GalleryStartPage {} }
}
