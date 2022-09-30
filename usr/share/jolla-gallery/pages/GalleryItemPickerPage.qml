import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0
import QtDocGallery 5.0

Page {
    id: root

    property alias model: selectionModel.docModel
    property string title
    signal itemsSelected(var items)

    allowedOrientations: Orientation.All

    function deleteClicked()
    {
        // Store selected items to the array
        var array = []
        for (var index = 0; index < selectionModel.count; index++) {
            if(selectionModel.get(index).selected) {
                array.push(selectionModel.get(index).url)
            }
        }

        // Emit signal with selected items, to indicate that selection is done
        itemsSelected(array)
    }

    function clearSelections()
    {
        selectionModel.selectOrClearAll(false)
    }

    function selectAll()
    {
        selectionModel.selectOrClearAll(true)
    }

    // A proxy model for hiding the DocumentGalleryModel and to provide selection role for
    // each item. This model also takes care of if items are removed or added in the background
    // while this Page is active to keep the content up-to-date.
    QtObject {
        id: selectionModel
        property bool ready
        property int count: model.count
        property int selectionCount: 0
        property ListModel model: ListModel {}
        property QtObject docModel
        property bool active: root.status === PageStatus.Active || root.status === PageStatus.Activating

        // Make sure not to call _update() when this page is not active anymore
        onActiveChanged: if (!active) docModel.countChanged.disconnect(_update)

        function get(index)
        {
            return model.get(index)
        }

        function selectOrClearAll(select)
        {
            for(var i=0; i < docModel.count; i++) {
                model.setProperty(i, "selected", select)
            }

            if (select) {
                selectionCount = count
            } else {
                selectionCount = 0
            }
        }

        function setSelected(index, selected)
        {
            model.setProperty(index, "selected", selected)

            if (selected) {
                ++selectionCount
            } else {
                --selectionCount
            }
        }

        function _itemAt(i) {
            if (i < 0 || i >= docModel.count) {
                console.warn("Calling GalleryItemPickerPage::_itemAt(i) out of bounds")
            }

            var item = {
                "url": "" + docModel.get(i).url,
                "mimeType": docModel.get(i).mimeType,
                "selected": false
            }

            if (docModel.rootType === DocumentGallery.Image) {
                item["dateTaken"] = docModel.get(i).dateTaken
            } else {
                item["lastModified"] = docModel.get(i).lastModified
            }
            return item
        }

        function _update()
        {
            if (active && docModel == null) {
                return
            }

            var i, j

            // First time initialization
            if (model.count == 0) {
                for(i=0; i < docModel.count; i++) {
                    model.insert(i, _itemAt(i))

                    // Just make the model ready when there are enough pics to show
                    if (i > 20) {
                        ready = true
                    }
                }
                // In a case we are not ready yet (<20 images) make the model ready
                ready = true

                // FIXME: UPDATING DISABLED - if update algorithm is n^2 it's just better not to update.
                // should be reimplemented
                //docModel.countChanged.connect(_update)
            }

            // TODO: Event though the next piece of code seems to block in some cases, I  think it's
            //       better to handle these rare situations that kee this view not up-to-date.
            //       Maybe using WorkerScript could provide some kind of solution for keeping model
            //       updated.

            var found
            var url

            // Images removed from the document model e.g. someone has removed the image via commandline
            if (model.count > docModel.count) {
                for (i=0; i < model.count; i++) {
                    url = model.get(i).url
                    found = false
                    for (j=0; j < docModel.count; j++) {
                        if (url == docModel.get(j).url) {
                            found = true
                            break
                        }
                    }

                    // Item is not in the DocumentGalleryModel anymore,
                    // so let's remove it.
                    if (!found) {
                        model.remove(i)
                    }
                }
            }

            // Images have been added
            if (model.count < docModel.count) {
                for (i=0; i < docModel.count; i++) {
                    url = docModel.get(i).url
                    found = false
                    for (j=0; j < model.count; j++) {
                        if (url == model.get(j).url) {
                            found = true
                        }
                    }
                    // New item, let's add it to the model
                    if (!found) {
                        if (i < model.count) {
                            model.insert(i, _itemAt(i))
                        } else {
                            model.append(i, _itemAt(i))
                        }
                    }
                }
            }
        }

        onDocModelChanged: if (docModel !== null) _update()
    }

    ImageGridView {
        id: grid

        model: selectionModel.ready ? selectionModel.model : null
        header: PageHeader { title: root.title }
        dateProperty: root.model.rootType === DocumentGallery.Image ? "dateTaken" : "lastModified"

        clip: true

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: controlPanel.top
        }

        PullDownMenu {
            MenuItem {
                //% "Clear All"
                text: qsTrId("gallery-me-clear-selections")
                onClicked: root.clearSelections()
                visible: selectionModel.selectionCount > 0
            }

            MenuItem {
                //% "Select All"
                text: qsTrId("gallery-me-select-all")
                onClicked: root.selectAll()
                visible: selectionModel.count !== selectionModel.selectionCount
            }
        }

        delegate: ThumbnailImage {
            id: thumbnail

            onClicked: selectionModel.setSelected(index, !model.selected)

            // Initialize selection status if delegate is instantiated again
            source: url
            selected: model.selected
        }
    }

    DockedPanel {
        id: controlPanel
        width: parent.width
        height: Theme.itemSizeLarge
        dock: Dock.Bottom
        open: selectionModel.selectionCount > 0

        Image {
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: "image://theme/graphic-gradient-edge"
        }

        IconButton {
            icon.source: "image://theme/icon-m-delete"
            anchors.centerIn: parent
            onClicked: root.deleteClicked()
        }
    }
}
