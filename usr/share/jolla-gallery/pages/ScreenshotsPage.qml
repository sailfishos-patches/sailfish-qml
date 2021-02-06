import QtQuick 2.0
import Sailfish.Silica 1.0

GalleryGridPage {

    SilicaFlickable {
        anchors.fill: parent
        enabled: model.count === 0

        ViewPlaceholder {
            enabled: model.count === 0
            //% "No screenshots"
            text: qsTrId("gallery-la-no_screenshots")
            //% "Take screenshots by simultaneously pressing down Volume up and down keys"
            hintText: qsTrId("gallery-la-take_screenshots_by_pressing_volume_keys")
        }
    }
}
