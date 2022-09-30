import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.camera 1.0

GalleryView {
    id: root

    captureModel: CaptureModel {
        id: model
        directories: Settings.storagePathStatus, [
            Settings.photoDirectory,
            Settings.videoDirectory
        ]
    }

    ViewPlaceholder {
        //: Placeholder text for an empty camera reel view
        //% "Captured photos and videos will appear here when you take some"
        text: qsTrId("camera-la-no-photos")
        enabled: model.count === 0 && model.populated
    }
}
