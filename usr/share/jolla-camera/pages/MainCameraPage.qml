import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.camera 1.0
import org.nemomobile.dbus 2.0

CameraPage {
    id: page
    galleryView: Qt.resolvedUrl("gallery/MainGalleryView.qml")

    Binding {
        target: window
        property: "galleryActive"
        value: page.galleryActive
    }

    Binding {
        target: window
        property: "galleryVisible"
        value: page.galleryVisible
    }

    Binding {
        target: window
        property: "galleryIndex"
        value: page.galleryIndex
    }

    Binding {
        target: window
        property: "captureModel"
        value: page.captureModel
    }

    Timer {
        running: Qt.application.state != Qt.ApplicationActive && !captureModeActive
        interval: 15*60*1000
        onTriggered: returnToCaptureMode()
    }

    DBusAdaptor {
        iface: "com.jolla.camera.ui"
        service: "com.jolla.camera"
        path: "/"

        signal showViewfinder(variant args)
        onShowViewfinder: {
            page.returnToCaptureMode()
            window.activate()
        }

        signal showFrontViewfinder()
        onShowFrontViewfinder: {
            Settings.cameraDevice = "secondary"
            page.returnToCaptureMode()
            window.activate()
        }
    }
}
