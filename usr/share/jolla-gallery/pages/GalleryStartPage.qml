import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Gallery 1.0
import Sailfish.Gallery.private 1.0
import com.jolla.gallery 1.0
import QtDocGallery 5.0
import Nemo.FileManager 1.0

Page {
    id: startPage

    property Page imageViewerPage: null

    allowedOrientations: Orientation.All

    function showPage(mediaSource) {
        pageStack.pop(startPage, PageStackAction.Immediate)
        showMedia(mediaSource, PageStackAction.Immediate)
        activate()
    }

    function showMedia(media, transition, index) {
        pageStack.animatorPush(Qt.resolvedUrl(media.page),
                               { title: media.title, model: media.model, userData: media.type },
                               transition !== undefined ? transition : PageStackAction.Animated)
    }

    function showImage(urls, viewerAction) {
        // To avoid mixed content e.g. videos and photos in the same model, just
        // clear everything each time when function is called.
        pageStack.pop(startPage, PageStackAction.Immediate)
        imageViewerPage = null
        viewerModel.clear()

        for (var i=0; i < urls.length; ++i) {
            var properties = {}
            var file = urls[i]
            fileInfo.url = file

            if (fileInfo.mimeType.indexOf("image/") === 0) {
                metadata.source = file
                properties = {
                    url: file,
                    mimeType: fileInfo.mimeType,
                    title: fileInfo.fileName,
                    orientation: metadata.orientation,
                    width: metadata.width,
                    height: metadata.height
                }

                if (fileInfo.url.toString().indexOf(StandardPaths.pictures + "/Screenshots/") >= 0) {
                    showPage(screenshotsSource)
                } else {
                    showPage(photoSource)
                }

            } else if (fileInfo.mimeType.indexOf("video") === 0) {
                properties = {
                    url: file,
                    mimeType: fileInfo.mimeType,
                    title: fileInfo.fileName,
                    orientation: 0
                }

                showPage(videoSource)
            }

            viewerModel.append(properties)
        }

        imageViewerPage = pageStack.push(
                        Qt.resolvedUrl("GalleryFullscreenPage.qml"),
                        { model: viewerModel,
                          currentIndex: viewerModel.count - urls.length
                        },
                        PageStackAction.Immediate)
        if (viewerAction) {
            imageViewerPage.triggerViewerAction(viewerAction, true)
        }
        metadata.source = ""
        fileInfo.url = ""
    }

    function playVideoStream(url) {
        // To avoid mixed content e.g. videos and photos in the same model, just
        // clear everything each time when function is called.
        imageViewerPage = null
        pageStack.pop(null, PageStackAction.Immediate)

        fileInfo.url = url

        viewerModel.clear()
        viewerModel.set(0, {
                               url: url,
                               mimeType: fileInfo.mimeType,
                               title: fileInfo.fileName,
                               orientation: 0
                           })

        imageViewerPage = pageStack.push(Qt.resolvedUrl("GalleryFullscreenPage.qml"),
                                                {
                                                    model: viewerModel,
                                                    currentIndex: 0,
                                                    viewerOnlyMode: true,
                                                    autoPlay: true
                                                }, PageStackAction.Immediate)
        activate()
        metadata.source = ""
        fileInfo.url = ""
    }

    Component.onCompleted: window.startPage = startPage

    ListModel { id: viewerModel }
    ImageMetadata { id: metadata }
    FileInfo { id: fileInfo }

    Component {
        id: delegate
        BackgroundItem {
            id: delegateItem
            width: view.width
            height: thumbnail.height
            enabled: media && (media.count > 0 || media.type === MediaSource.Screenshots)
            opacity: enabled ? 1.0 : Theme.opacityLow

            Label {
                id: countLabel

                // Unlocalized helper property for testing purposes.
                readonly property int count: media ? media.count : 0

                objectName: "countLabel"
                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingMedium
                    right: thumbnail.left
                    rightMargin: Theme.paddingLarge
                    verticalCenter: parent.verticalCenter
                }
                opacity: Theme.opacityLow
                text: media.busy && count == 0 ? "" : count.toLocaleString()
                color: delegateItem.down ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeLarge
                horizontalAlignment: Text.AlignRight
                fontSizeMode: Text.HorizontalFit
            }

            // Load icon from a plugin
            Loader {
                id: thumbnail
                x: Theme.itemSizeExtraLarge + Theme.horizontalPageMargin - Theme.paddingLarge
                width: Theme.itemSizeExtraLarge
                height: width
                source: media.icon
                opacity: delegateItem.down ? Theme.opacityHigh : 1
                onStatusChanged: {
                    if (status == Loader.Ready) {
                        item.model = media.model
                    }
                }
            }

            BusyIndicator {
                anchors.centerIn: thumbnail
                running: media.busy
            }

            Label {
                id: titleLabel
                objectName: "titleLabel"
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeLarge
                text: media.title
                color: delegateItem.down ? Theme.highlightColor : Theme.primaryColor
                anchors {
                    left: thumbnail.right
                    right: parent.right
                    leftMargin: Theme.paddingLarge
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
            }

            onClicked: showMedia(media)
        }
    }

    SilicaListView {
        id: view
        objectName: "albumsView"
        anchors.fill: parent
        delegate: delegate
        model: MediaSourceModel {
            MediaSource {
                id: photoSource
                //: Main screen
                //% "Photos"
                title: qsTrId("gallery-bt-photos")
                icon: "PhotoIcon.qml"
                page: "GalleryGridPage.qml"
                model: photosModel
                ready: true
                busy: model.status == DocumentGalleryModel.Active
                count: model ? model.count : 0
                type: MediaSource.Photos
            }

            MediaSource {
                id: videoSource
                //% "Videos"
                title: qsTrId("gallery-bt-videos")
                icon: "VideoIcon.qml"
                page: "GalleryGridPage.qml"
                model: videosModel
                ready: true
                busy: model.status == DocumentGalleryModel.Active
                count: model ? model.count : 0
                type: MediaSource.Videos
            }

            MediaSource {
                id: screenshotsSource
                //% "Screenshots"
                title: qsTrId("gallery-bt-screenshots")
                icon: "ScreenshotIcon.qml"
                page: "ScreenshotsPage.qml"
                model: screenshotsModel
                ready: true
                busy: model.status == DocumentGalleryModel.Active
                count: model ? model.count : 0
                type: MediaSource.Screenshots
            }

            MediaSource {
                //% "Android™ storage"
                title: qsTrId("gallery-bt-android_storage")
                icon: "PhotoIcon.qml"
                page: "GalleryGridPage.qml"
                model: androidStorage
                ready: FileEngine.exists(androidStorage.path)
                busy: model.status == DocumentGalleryModel.Active
                count: model ? model.count : 0
                type: MediaSource.Photos
            }
        }

        VerticalScrollDecorator {}
    }

    GalleryService {
        onActivate: window.activate()

        onOpenImages:{
            if (urls.length > 0) {
                showImage(urls, viewerAction)
            }
            window.activate()
        }

        onPlayStream: startPage.playVideoStream(url)

        onShowAllPhotos: showPage(photoSource)
        onShowAllVideos: showPage(videoSource)
        onShowAllScreenshots: showPage(screenshotsSource)
    }
}
