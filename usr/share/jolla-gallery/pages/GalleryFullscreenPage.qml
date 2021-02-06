import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0
import com.jolla.gallery 1.0

FullscreenContentPage {
    id: root

    property alias model: imageView.model
    property alias currentIndex: imageView.currentIndex
    property alias autoPlay: imageView.autoPlay
    property alias viewerOnlyMode: imageView.viewerOnlyMode

    signal requestIndex(int index)

    function triggerViewerAction(action, immediately) {
        imageView.triggerViewerAction(action, immediately)
    }

    objectName: "fullscreenPage"
    allowedOrientations: Orientation.All

    // Update the Cover via window.activeObject property
    Binding {
        target: window
        property: "activeObject"
        property bool active: root.status === PageStatus.Active
        value: { "url": active ? fileInfo.source : "", "mimeType": active ? fileInfo.mimeType : "" }
    }
    FileInfo {
        id: fileInfo
        source: {
            if (model && model.count >= imageView.currentIndex - 1) {
                var data = model.get(imageView.currentIndex)
                return data ? data.url : ""
            }
            return ""
        }
    }

    onCurrentIndexChanged: {
        if (status !== PageStatus.Active) {
            return
        }
        if (model === undefined || currentIndex >= model.count) {
            // This can happen if all of the images are deleted
            var firstPage = pageStack.previousPage(root)
            while (pageStack.previousPage(firstPage)) {
                firstPage = pageStack.previousPage(firstPage)
            }
            pageStack.pop(firstPage)
            return
        }
        requestIndex(currentIndex)
        pageStack.previousPage(root).jumpToIndex(currentIndex)
    }

    // Element for handling the actual flicking and image buffering
    FlickableImageView {
        id: imageView

        anchors.fill: parent
        objectName: "flickableView"
    }
    VerticalPageBackHint {}
}
