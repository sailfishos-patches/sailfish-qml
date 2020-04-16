import QtQuick 2.0
import Sailfish.Silica 1.0
import QtDocGallery 5.0
import com.jolla.gallery 1.0
import Sailfish.Gallery 1.0
import "scripts/AlbumManager.js" as AlbumManager

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

        property alias contextMenu: contextMenuItem
        property Item expandItem
        property real expandHeight: contextMenu.height
        property int minOffsetIndex: expandItem != null
                                     ? expandItem.modelIndex + columnCount - (expandItem.modelIndex % columnCount)
                                     : 0

        anchors.fill: parent
        header: PageHeader { title: gridPage.title }
        model: gridPage.model

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
            size: grid.cellSize
            height: isItemExpanded ? grid.contextMenu.height + grid.cellSize : grid.cellSize
            contentYOffset: index >= grid.minOffsetIndex ? grid.expandHeight : 0.0
            z: isItemExpanded ? 1000 : 1
            enabled: isItemExpanded || !grid.contextMenu.active

            function remove() {
                var remorse = removalComponent.createObject(null)
                remorse.z = thumbnail.z + 1

                remorse.execute(remorseContainerComponent.createObject(thumbnail),
                                remorse.text,
                                function() {
                                    AlbumManager.deleteMedia(thumbnail.mediaUrl)
                                })
            }


            onClicked: {
                if (grid.contextMenu.active) {
                    return
                }

                pageStack.push(Qt.resolvedUrl("GalleryFullscreenPage.qml"),
                               {currentIndex: index, model: grid.model})
                _requestedIndex = -1
                pageStack.currentPage.requestIndex.connect(gridPage.requestIndex)
            }

            onPressAndHold: {
                grid.expandItem = thumbnail
                grid.contextMenu.open(thumbnail)
            }

            GridView.onAdd: AddAnimation { target: thumbnail; duration: _animationDuration }
            GridView.onRemove: SequentialAnimation {
                PropertyAction { target: thumbnail; property: "GridView.delayRemove"; value: true }
                NumberAnimation { target: thumbnail; properties: "opacity,scale"; to: 0; duration: 250; easing.type: Easing.InOutQuad }
                PropertyAction { target: thumbnail; property: "GridView.delayRemove"; value: false }
            }
        }

        ContextMenu {
            id: contextMenuItem
            x: parent !== null ? -parent.x : 0.0

            MenuItem {
                objectName: "deleteItem"
                //% "Delete"
                text: qsTrId("gallery-me-delete")
                onClicked: grid.expandItem.remove()
            }
        }
    }

    // This container is used for making RemorseItem to follow
    // offset changes if there are multiple deletions ongoing
    // at the same time.
    Component {
        id: remorseContainerComponent
        Item {
            y: parent.contentYOffset
            width: parent.width
            height: parent.height
        }
    }

    Component {
        id: removalComponent
        RemorseItem {
            objectName: "remorseItem"
            font.pixelSize: Theme.fontSizeSmallBase
        }
    }
}
