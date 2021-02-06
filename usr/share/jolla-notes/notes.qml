import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import "pages"

ApplicationWindow
{
    id: app

    property Item currentNotePage

    initialPage: Component {
        OverviewPage {
            id: overviewpage
            property Item currentPage: pageStack.currentPage
            onCurrentPageChanged: {
                if (currentPage == overviewpage) {
                    currentNotePage = null
                } else if (currentPage.hasOwnProperty("__jollanotes_notepage")) {
                    currentNotePage = currentPage
                }
            }
        }
    }
    cover: Qt.resolvedUrl("cover/NotesCover.qml")
    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    // exposed as a property so that the tests can access it
    property NotesModel notesModel: NotesModel { id: notesModel }

    function openNewNote(operationType) {
        pageStack.pop(null, PageStackAction.Immediate)
        pageStack.animatorPush(notePage, {potentialPage: 1, editMode: true}, operationType)
    }

    Component {
        id: notePage
        NotePage { }
    }

    DBusAdaptor {
        service: "com.jolla.notes"
        path: "/"
        iface: "com.jolla.notes"

        function newNote() {
            if (pageStack.currentPage.__jollanotes_notepage === undefined || pageStack.currentPage.currentIndex >= 0) {
                // don't open a new note if already showing a new unedited note
                openNewNote(PageStackAction.Immediate)
            }
            app.activate()
        }

        function importNoteFile(pathList) {
            // If the user has an empty note open (or we automatically pushed newNote
            // page due to having no notes) then we need to pop that page.
            if (pageStack.currentPage.__jollanotes_notepage !== undefined) {
                pageStack.pop(null, PageStackAction.Immediate)
            }

            // For compatibility reasons this signal sometimes receives an array of strings
            var filePath
            if (typeof pathList === 'string') {
                filePath = pathList
            } else if (typeof pathList === 'object' && pathList.length !== undefined && pathList.length > 0) {
                filePath = pathList[0]
                if (pathList.length > 1) {
                    console.warn('jolla-notes: Importing only first path from:', pathList)
                }
            }
            if (filePath && (String(filePath) != '')) {
                console.log('jolla-notes: Importing note file:', filePath)
                var plaintextNotes = vnoteConverter.importFromFile(filePath)
                if (plaintextNotes.length === 0) {
                    var filename = filePath.substring(filePath.lastIndexOf("/") + 1)
                    //% "Unable to import: %1"
                    Notices.show(qsTrId("notes-la-unable_to_open").arg(filename))
                }

                for (var index = 0; index < plaintextNotes.length; ++index) {
                    // insert the note into the database
                    notesModel.newNote(index + 1, plaintextNotes[index], notesModel.nextColor())
                }
                if (plaintextNotes.length === 1 && pageStack.depth === 1) {
                    pageStack.push(notePage, {currentIndex: -1}, PageStackAction.Immediate)
                } else for (index = 0; index < plaintextNotes.length; ++index) {
                    if (pageStack.depth === 1) {
                        // the current page is the overview page.  indicate to the user which notes were imported,
                        // by flashing the delegates of the imported notes in the gridview.
                        pageStack.currentPage.flashGridDelegate(index)
                    } else {
                        // a note is currently open.  Queue up the indication to the user
                        // so that it gets displayed when they next return to the gridview.
                        var overviewPage = pageStack.previousPage(app.currentNotePage)
                        overviewPage._flashDelegateIndexes[overviewPage._flashDelegateIndexes.length] = index
                    }
                }
                app.activate()
            }
        }

        function activateWindow(arg) {
            app.activate()
        }
    }
}
