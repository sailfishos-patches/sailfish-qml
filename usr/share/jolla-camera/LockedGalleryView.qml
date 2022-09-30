import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.camera 1.0
import QtQuick.Window 2.1
import Nemo.FileManager 1.0
import Nemo.DBus 2.0

GalleryView {
    id: root
    property bool hidden: window.Window.visibility === Window.Hidden
    onHiddenChanged: {
        if (hidden) {
            captureModel.clear()
            page.returnToCaptureMode()
        }
    }

    captureModel: ListModel {
        function appendCapture(url, mimeType) {
            insert(0, { url: url + "", mimeType: mimeType })
        }
        function deleteFile(index) {
            FileEngine.deleteFiles([get(index).url])
            remove(index)
        }
    }
    overlay.sharingAllowed: false
    overlay.ambienceAllowed: false
    overlay.additionalActions: IconButton {
        icon.source: "image://theme/icon-m-file-image?" + Theme.lightPrimaryColor
        onClicked: {
            var source = root.source + ""
            dbusGallery.call('openFile', source)
        }
    }

    ViewPlaceholder {
        //: Placeholder text for an empty camera reel view
        //% "New photos and videos you take will appear here"
        text: qsTrId("camera-la-no_photos_lockscreen")
        //% "Unlock the device to access older photos and videos"
        hintText: qsTrId("camera-la-unlock_device_to_access_photos_and_videos")
        enabled: count == 0
    }

    DBusInterface {
        id: dbusGallery

        service: "com.jolla.gallery"
        path: "/com/jolla/gallery/ui"
        iface: "com.jolla.gallery.ui"
    }
}
