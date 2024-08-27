/*
 * Copyright (c) 2013 - 2021 Jolla Ltd.
 * Copyright (c) 2021 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Sailfish.Gallery 1.0

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
        localFile: false
        anchors.fill: parent
        additionalActions: Component {
            IconButton {
                icon.source: "image://theme/icon-m-cloud-download"
                onClicked: {
                    root.copy()
                    pageStack.pop()
                }
            }
        }

        Private.DismissButton {}
    }
}
