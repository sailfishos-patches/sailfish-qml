import QtQuick 2.0
import Sailfish.Silica 1.0
import QtDocGallery 5.0
import com.jolla.gallery 1.0
import Sailfish.Gallery 1.0

MediaSourcePage {
    id: gridPage
    property alias currentIndex: grid.currentIndex
    property int _animationDuration: 150
    property var _selectedItems: null
    property int _requestedIndex: -1

    allowedOrientations: Orientation.All

    objectName: "gridPage"

    function deleteMultipleItems(list) {
        _selectedItems = list
        pageStack.pop()

        Remorse.popupAction(
            gridPage,
            //: Remorse popup for multiple image deletion
            //% "Deleting %n item(s)"
            qsTrId("gallery-me-deleting-%1-items", _selectedItems.length), function() {
            if (!_selectedItems) {
                console.log("deleteMultipleItems: no selected files!")
                return
            }
            fileRemover.deleteFiles(_selectedItems)
        })
    }

    function requestIndex(index) {
        _requestedIndex = index
    }

    function jumpToIndex(index) {
        if (index < grid.columnCount)
            grid.positionViewAtBeginning()
        else
            grid.positionViewAtIndex(index, GridView.Visible)
        grid.currentIndex = index
    }

    onStatusChanged: {
        if (status == PageStatus.Activating && _requestedIndex != -1) {
            jumpToIndex(_requestedIndex)
        }
    }

    Connections {
        target: gridPage.model
        onCountChanged: {
            if (gridPage.model.count === 0 && !pageStack.busy) {
                pageStack.pop(pageStack.previousPage(gridPage))
            }
        }
    }

    // File remover is a threaded object which can be used for file deletion in the background.
    // TODO: Not sure how we should deal with the error cases e.g. file couldn't be deleted and
    //       we don't even have a design for that yet.
    FileRemover {
        id: fileRemover
        onFinished: _selectedItems = null
    }

    ImageGridView {
        id: grid
        objectName: "gridView"

        anchors.fill: parent
        header: PageHeader { title: gridPage.title }
        model: gridPage.model
        dateProperty: model.rootType === DocumentGallery.Image ? "dateTaken" : "lastModified"

        PullDownMenu {
            visible: model.count > 0
            MenuItem {
                //: Select multiple videos for different operations
                //% "Select videos"
                property string selectVideosText: qsTrId("gallery-me-select-videos")
                //: Select multiple images for different operations
                //% "Select photos"
                property string selectPhotosText: qsTrId("gallery-me-select-photos")
                //: Select multiple images for different operations
                //% "Select screenshots"
                property string selectScreenshotsText: qsTrId("gallery-me-select-screenshots")

                text: gridPage.userData === MediaSource.Photos
                      ? selectPhotosText
                      : (gridPage.userData === MediaSource.Videos ? selectVideosText : selectScreenshotsText)
                onClicked: {
                    var obj = pageStack.animatorPush(Qt.resolvedUrl("GalleryItemPickerPage.qml"),{
                                               model: grid.model,
                                               title: text
                                           })
                    obj.pageCompleted.connect(function(page) {
                        page.itemsSelected.connect(gridPage.deleteMultipleItems)
                    })
                }
            }
        }

        delegate: ThumbnailImage {
            id: thumbnail

            property bool isItemExpanded: grid.expandItem === thumbnail
            property url mediaUrl: url
            property int modelIndex: index

            source: mediaUrl

            function remove() {
                remorseDelete(function() { fileRemover.deleteFileSync(thumbnail.mediaUrl) })
            }

            onClicked: {
                pageStack.push(Qt.resolvedUrl("GalleryFullscreenPage.qml"),
                               {currentIndex: index, model: grid.model})
                _requestedIndex = -1
                pageStack.currentPage.requestIndex.connect(gridPage.requestIndex)
            }

            menu: Component {
                ContextMenu {
                    MenuItem {
                        objectName: "deleteItem"
                        //% "Delete"
                        text: qsTrId("gallery-me-delete")
                        onClicked: remove()
                    }
                }
            }

            GridView.onAdd: AddAnimation { target: thumbnail; duration: _animationDuration }
            GridView.onRemove: SequentialAnimation {
                PropertyAction { target: thumbnail; property: "GridView.delayRemove"; value: true }
                NumberAnimation { target: thumbnail; properties: "opacity,scale"; to: 0; duration: 250; easing.type: Easing.InOutQuad }
                PropertyAction { target: thumbnail; property: "GridView.delayRemove"; value: false }
            }
        }
    }
}
