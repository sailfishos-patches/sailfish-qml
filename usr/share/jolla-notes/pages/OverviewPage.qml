import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: overviewpage

    function showDeleteNote(index) {
        // This is needed both for UI (the user should see the remorse item)
        // and to make sure the delegate exists.
        view.positionViewAtIndex(index, GridView.Contain)
        // Set currentIndex in order to find the corresponding currentItem.
        // Is this really the only way to look up a delegate by index?
        view.currentIndex = index
        view.currentItem.deleteNote()
    }
    function flashGridDelegate(index) {
        // This is needed both for UI (the user should see the remorse item)
        // and to make sure the delegate exists.
        view.positionViewAtIndex(index, GridView.Contain)
        // Set currentIndex in order to find the corresponding currentItem.
        // Is this really the only way to look up a delegate by index?
        view.currentIndex = index
        view.currentItem.flash()
    }
    property var _flashDelegateIndexes: []

    readonly property bool populated: notesModel.populated
    onPopulatedChanged: {
        if (notesModel.count === 0) {
            openNewNote(PageStackAction.Immediate)
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            if (populated && _flashDelegateIndexes.length) {
                // Flash grid delegates of imported notes
                for (var i in _flashDelegateIndexes) {
                    flashGridDelegate(_flashDelegateIndexes[i])
                }
                _flashDelegateIndexes = []
            }
            if (notesModel.filter.length > 0) {
                notesModel.refresh() // refresh search
            }
        } else if (status === PageStatus.Inactive) {
            if (notesModel.filter.length == 0) view.headerItem.active = false
        }
    }

    SilicaGridView {
        id: view

        currentIndex: -1
        anchors.fill: overviewpage
        model: notesModel
        cellHeight: overviewpage.width / columnCount
        cellWidth: cellHeight
        // reference column width: 960 / 4
        property int columnCount: Math.floor((isLandscape ? Screen.height : Screen.width) / (Theme.pixelRatio * 240))

        onMovementStarted: {
            focus = false   // close the vkb
        }

        ViewPlaceholder {
            id: placeholder

            // Avoid flickering empty state placeholder when updating search results
            function placeholderText() {
                //% "Sorry, we couldn't find anything"
                return notesModel.filter.length > 0 ? qsTrId("notes-la-could_not_find_anything")
                                                      //: Comforting text when overview is empty
                                                      //% "Write a note"
                                                    : qsTrId("notes-la-overview-placeholder")
            }
            Component.onCompleted: text = placeholderText()
            Binding {
                when: placeholder.opacity == 0.0
                target: placeholder
                property: "text"
                value: placeholder.placeholderText()
            }

            enabled: notesModel.populated && notesModel.count === 0
        }
        header: SearchField {
            width: parent.width
            canHide: text.length === 0
            active: false
            inputMethodHints: Qt.ImhNone    // Enable predictive text

            onHideClicked: {
                active = false
            }

            onTextChanged: notesModel.filter = text

            EnterKey.iconSource: "image://theme/icon-m-enter-close"
            EnterKey.onClicked: focus = false
        }

        delegate: NoteItem {
            id: noteItem

            // make model.index accessible to other delegates
            property int index: model.index

            function deleteNote() {
                remorseDelete(function() {
                    notesModel.deleteNote(index)
                })
            }

            function flash() {
                flashAnim.running = true
            }


            text: model.text ? Theme.highlightText(model.text.substr(0, Math.min(model.text.length, 300)), notesModel.filter, Theme.highlightColor) : ""
            color: model.color
            pageNumber: model.pagenr
            menu: contextMenuComponent

            onClicked: pageStack.animatorPush(notePage, { currentIndex: model.index } )

            Rectangle {
                id: flashRect
                anchors.fill: parent
                color: noteItem.color
                opacity: 0.0
                SequentialAnimation {
                    id: flashAnim
                    running: false
                    PropertyAnimation { target: flashRect; property: "opacity"; to: Theme.opacityLow; duration: 600; easing.type: Easing.InOutQuad }
                    PropertyAnimation { target: flashRect; property: "opacity"; to: 0.01; duration: 600; easing.type: Easing.InOutQuad }
                    PropertyAnimation { target: flashRect; property: "opacity"; to: Theme.opacityLow; duration: 600; easing.type: Easing.InOutQuad }
                    PropertyAnimation { target: flashRect; property: "opacity"; to: 0.00; duration: 600; easing.type: Easing.InOutQuad }
                }
            }
        }

        PullDownMenu {
            id: pullDownMenu

            MenuItem {
                visible: notesModel.filter.length > 0 || notesModel.count > 0
                //% "Search"
                text: qsTrId("notes-me-search")
                onClicked: {
                    view.headerItem.active = true
                    view.headerItem.forceActiveFocus()
                }
            }

            MenuItem {
                //: Create a new note ready for editing
                //% "New note"
                text: qsTrId("notes-me-new-note")
                onClicked: app.openNewNote(PageStackAction.Animated)
            }
        }
        VerticalScrollDecorator {}
    }

    Component {
        id: contextMenuComponent
        ContextMenu {
            id: contextMenu

            MenuItem {
                //: Delete this note from overview
                //% "Delete"
                text: qsTrId("notes-la-delete")
                onClicked: contextMenu.parent.deleteNote()
            }

            MenuItem {
                //: Move this note to be first in the list
                //% "Move to top"
                text: qsTrId("notes-la-move-to-top")
                visible: contextMenu.parent && contextMenu.parent.index > 0
                property int index
                onClicked: index = contextMenu.parent.index // parent is null by the time delayedClick() is called
                onDelayedClick: notesModel.moveToTop(index)
            }
        }
    }
}
