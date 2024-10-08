import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Gallery 1.0
import Sailfish.Gallery.private 1.0

/*!
  \inqmlmodule Sailfish.Gallery
*/
ZoomableFlickable {
    id: flickable

    property alias source: photo.source

    property bool active: true
    /*!
      \internal
    */
    readonly property bool _active: active || viewMoving
    readonly property bool error: photo.status == Image.Error
    readonly property alias imageMetaData: metadata

    property alias photo: photo
    property alias largePhoto: largePhoto

    signal clicked

    onAboutToZoom: {
        if (largePhoto.source != photo.source) {
            largePhoto.source = photo.source
        }
    }

    contentRotation: -metadata.orientation
    scrollDecoratorColor: Theme.lightPrimaryColor

    zoomEnabled: photo.status == Image.Ready
    maximumZoom: Math.max(Screen.width, Screen.height) / 200
                 * Math.max(1.0, photo.implicitWidth > 0 ? largePhoto.implicitHeight / photo.implicitHeight
                                                         : 1.0)

    on_ActiveChanged: {
        if (!_active) {
            resetZoom()
            largePhoto.source = ""
        }
    }

    implicitContentWidth: photo.implicitWidth
    implicitContentHeight: photo.implicitHeight

    Image {
        id: photo
        property var errorLabel
        objectName: "zoomableImage"

        anchors.fill: parent
        smooth: !(movingVertically || movingHorizontally)
        sourceSize.width: Screen.height
        fillMode: Image.PreserveAspectFit
        visible: largePhoto.status !== Image.Ready
        asynchronous: true
        cache: false

        onStatusChanged: {
            if (status == Image.Error) {
                errorLabel = errorLabelComponent.createObject(flickable)
            }
        }

        onSourceChanged: {
            if (errorLabel) {
                errorLabel.destroy()
                errorLabel = null
            }

            resetZoom()
        }

        opacity: status == Image.Ready ? 1 : 0
        Behavior on opacity { FadeAnimation{} }
    }

    Image {
        id: largePhoto
        sourceSize {
            width: 3264
            height: 3264
        }
        cache: false
        asynchronous: true
        anchors.fill: parent
    }

    Item {
        width: flickable.transpose ? parent.height : parent.width
        height: flickable.transpose ? parent.width : parent.height

        anchors.centerIn: parent
        rotation: -flickable.contentRotation

        MouseArea {
            x: width > parent.width
                    ? (parent.width - width) / 2
                    : flickable.contentX + Theme.paddingLarge
            y: height > parent.height
                    ? (parent.height - height) / 2
                    : flickable.contentY + Theme.paddingLarge

            width: flickable.width - (2 * Theme.paddingLarge)
            height: flickable.height - (2 * Theme.paddingLarge)

            onClicked: flickable.clicked()
        }
    }

    ImageMetadata {
        id: metadata

        source: photo.source
        autoUpdate: false
    }

    BusyIndicator {
        running: photo.status === Image.Loading && !delayBusyIndicator.running
        size: BusyIndicatorSize.Large
        anchors.centerIn: parent
        parent: flickable
        Timer {
            id: delayBusyIndicator
            running: photo.status === Image.Loading
            interval: 1000
        }
    }

    Component {
        id: errorLabelComponent
        InfoLabel {
            //: Image loading failed
            //% "Couldn't load the image. It could have been deleted or become inaccessible."
            text: qsTrId("components_gallery-la-image-loading-failed-inaccessible")
            anchors.verticalCenter: parent.verticalCenter
            opacity: photo.status == Image.Error ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {}}
        }
    }
}
