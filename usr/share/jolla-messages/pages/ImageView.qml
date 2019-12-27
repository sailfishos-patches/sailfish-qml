import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Sailfish.Gallery 1.0
import Sailfish.TransferEngine 1.0

FullscreenContentPage {
    id: root
    property alias source: viewer.source
    property var messagePart

    signal copy()

    allowedOrientations: Orientation.All

    ImageViewer {
        id: viewer
        anchors.fill: parent
        onZoomedChanged: overlay.active = !zoomed
        onClicked: {
            if (zoomed) {
                zoomOut()
            } else {
                overlay.active = !overlay.active
            }
        }
    }

    GalleryOverlay {
        id: overlay

        source: viewer.source
        deletingAllowed: false
        editingAllowed: false
        isImage: true
        anchors.fill: parent
        additionalShareComponent: Component {
            ShareMethodItem {
                iconSource: "image://theme/icon-m-share-gallery"
                //% "Save to Gallery"
                text: qsTrId("jolla-messages-save_image_to_gallery")
                onClicked: {
                    root.copy()
                    pageStack.pop(root)
                }
            }
        }

        Private.DismissButton {}
    }
}
