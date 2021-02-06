import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

Page {
    id: page

    // currentIndex is for allocated notes.
    // potentialPage is for empty notes that haven't been added to the db yet.
    property int currentIndex: -1
    property int potentialPage
    property alias editMode: textArea.focus
    property alias text: textArea.text
    property alias color: noteview.color
    property alias pageNumber: noteview.pageNumber
    property bool loaded  // only load from notesModel[currentIndex] once

    property bool __jollanotes_notepage

    highContrast: true

    // TODO: should some kind of IndexConnection go into the silica components?
    Connections {
        target: notesModel

        onRowsRemoved: {
            console.log("Notes removed: " + first + ".." + last)
            if (currentIndex >= first) {
                if (currentIndex > last) {
                    currentIndex -= (last - first + 1)
                } else {
                    // current note was deleted; turn it into a potential note
                    potentialPage = pageNumber
                }
            }
        }

        onRowsInserted: {
            console.log("Notes inserted: " + first + ".." + last)
            if (currentIndex >= first)
                currentIndex += (last - first + 1)
        }

        onRowsMoved: {
            console.log("Notes moved: " + start + ".." + end + " -> " + row)
            // start and end are indexes from before the move,
            // "row" is start's new index after the move
            var numMoved = end - start + 1
            if (currentIndex >= start && currentIndex <= end) {
                // current note was among those moved
                currentIndex += start - row
            } else if (currentIndex > end && currentIndex < row + numMoved) {
                // moved notes jumped over current note
                currentIndex -= numMoved
            } else if (currentIndex < start && currentIndex >= row) {
                // moved notes jumped before current note
                currentIndex += numMoved
            }
        }
        onNewNoteInserted: currentIndex = 0
    }

    onCurrentIndexChanged: {
        if (!loaded && currentIndex >= 0 && currentIndex < notesModel.count) {
            potentialPage = 0
            var item = notesModel.get(currentIndex)
            noteview.savedText = item.text
            noteview.text = item.text
            noteview.color = item.color
            noteview.pageNumber = item.pagenr
            loaded = true
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            if (currentIndex >= 0 && noteview.text.trim() == '') {
                notesModel.deleteNote(currentIndex)
                currentIndex = -1
            } else {
                saveNote()
            }
        }
    }

    function saveNote() {
        var text = textArea.text
        if (text != noteview.savedText) {
            noteview.savedText = text
            if (potentialPage) {
                if (text.trim() != '') {
                    notesModel.newNote(potentialPage, text, noteview.color)
                    return true
                }
            } else {
                notesModel.updateNote(currentIndex, text)
                return true
            }
        }
        return false
    }

    onPotentialPageChanged: {
        if (potentialPage) {
            currentIndex = -1
            noteview.savedText = ''
            noteview.text = ''
            noteview.color = notesModel.nextColor()
            noteview.pageNumber = potentialPage
        }
    }

    function openColorPicker() {
        var obj = pageStack.animatorPush("Sailfish.Silica.ColorPickerPage",
                                         {"colors": notesModel.availableColors})
        obj.pageCompleted.connect(function(page) {
            page.colorClicked.connect(function(color) {
                noteview.color = color
                if (currentIndex >= 0) {
                    notesModel.updateColor(currentIndex, color)
                }
                pageStack.pop()
            })
        })
    }

    function noteFileName(noteText) {
        // Return a name for this vnote that can be used as a filename

        // Remove any whitespace
        var noWhitespace = noteText.replace(/\s/g, '')

        // shorten
        var shortened = noWhitespace.slice(0, Math.min(8, noWhitespace.length))

        // Convert to 7-bit ASCII
        var sevenBit = Format.formatText(shortened, Formatter.Ascii7Bit)
        if (sevenBit.length < shortened.length) {
            // This note's name is not representable in ASCII
            //: Placeholder name for note filename
            //% "note"
            sevenBit = qsTrId("notes-ph-default-note-name")
        }

        // Remove any characters that are not part of the portable filename character set
        return Format.formatText(sevenBit, Formatter.PortableFilename)
    }

    SilicaFlickable {
        id: noteview

        property color color: "white"
        property alias text: textArea.text
        property int pageNumber
        property string savedText

        anchors.fill: parent

        // The PullDownMenu doesn't work if contentHeight is left implicit.
        // It also doesn't work if contentHeight ends up equal to the
        // page height, so add some padding.
        contentHeight: column.y + column.height

        PullDownMenu {
            id: pulley

            MenuItem {
                //% "Change color"
                text: qsTrId("notes-me-note-color")
                onClicked: openColorPicker()
            }
            MenuItem {
                //: Delete this note from note page
                //% "Delete"
                text: qsTrId("notes-me-delete-note")
                onClicked: deleteNoteAnimation.restart()
                SequentialAnimation {
                    id: deleteNoteAnimation
                    NumberAnimation {
                        target: noteview
                        property: "opacity"
                        duration: 200
                        easing.type: Easing.InOutQuad
                        to: 0.0
                    }
                    ScriptAction {
                        script: {
                            // If the note text is empty then the note
                            // will be deleted by onStatusChanged, and
                            // there should not be a remorse timer etc.
                            if (page.currentIndex >= 0
                                    && noteview.text.trim() != '') {
                                var overview = pageStack.previousPage()
                                overview.showDeleteNote(page.currentIndex)
                            }
                            pageStack.pop(null, PageStackAction.Immediate)
                            noteview.opacity = 1.0
                        }
                    }
                }
            }
            MenuItem {
                //: This menu option can be used to share the note via Bluetooth
                //% "Share"
                text: qsTrId("notes-me-share-note")
                enabled: noteview.text.trim() != ''
                onClicked: {
                    var fileName = page.noteFileName(noteview.text) + (transferAsVNoteConfig.value == true ? ".vnt" : ".txt")
                    var mimeType = transferAsVNoteConfig.value == true ? "text/x-vnote" : "text/plain"
                    // vnoteConverter is a global installed by notes.cpp
                    var noteText = transferAsVNoteConfig.value == true ? vnoteConverter.vNote(textArea.text) : textArea.text
                    var content = {
                        "name": fileName,
                        "data": noteText,
                        "type": mimeType
                    }

                    if (mimeType == "text/plain") {
                        // also some non-standard fields for Twitter/Facebook status sharing:
                        content["status"] = noteText
                        content["linkTitle"] = fileName
                    }

                    pageStack.animatorPush("Sailfish.TransferEngine.SharePage",
                                           {
                                               //: Page header for share method selection
                                               //% "Share note"
                                               "header": qsTrId("notes-he-share-note"),
                                               "serviceFilter": ["sharing", "e-mail", "IM"],
                                               "mimeType": mimeType,
                                               "content": content
                                           })
                }
            }
            MenuItem {
                id: saveItem
                enabled: !saving

                property bool saving

                function replace(force) {
                    if (!newNoteAnimation.running || force) {
                        app.pageStack.replace(notePage, {
                                                  potentialPage: 1,
                                                  editMode: true
                                              }, PageStackAction.Immediate)
                        notesModel.newNoteInserted.disconnect(replace)
                        saving = false
                    }
                }

                //: Create a new note ready for editing
                //% "New note"
                text: qsTrId("notes-me-new-note")

                onDelayedClick: {
                    if (saveNote()) {
                        saving = true
                        notesModel.newNoteInserted.connect(replace)
                    }
                    newNoteAnimation.restart()
                }


                SequentialAnimation {
                    id: newNoteAnimation
                    NumberAnimation {
                        target: noteview
                        property: "opacity"
                        duration: 200
                        easing.type: Easing.InOutQuad
                        to: 0.0
                    }
                    ScriptAction {
                        script: saveItem.replace(true)
                    }
                }
            }
        }

        Column {
            id: column
            width: page.width

            Item {
                id: headerItem
                width: parent.width
                height: Theme.itemSizeLarge

                ColorItem {
                    id: colorItem
                    color: noteview.color
                    pageNumber: noteview.pageNumber
                    onClicked: openColorPicker()
                }
            }
            TextArea {
                id: textArea
                font { family: Theme.fontFamily; pixelSize: Theme.fontSizeMedium }
                width: parent.width
                height: Math.max(noteview.height - headerItem.height, implicitHeight)
                //: Placeholder text for new notes. At this point there's
                //: nothing else on the screen.
                //% "Write a note..."
                placeholderText: qsTrId("notes-ph-empty-note")
                color: Theme.primaryColor
                backgroundStyle: TextEditor.NoBackground

                onTextChanged: saveTimer.restart()
                Timer {
                    id: saveTimer
                    interval: 5000
                    onTriggered: page.saveNote()
                }
                Connections {
                    target: Qt.application
                    onActiveChanged: if (!Qt.application.active) page.saveNote()
                }
            }
        }
        VerticalScrollDecorator {}
    }

    ConfigurationValue {
        id: transferAsVNoteConfig
        key: "/apps/jolla-notes/settings/transferAsVNote"
        defaultValue: false
    }
}
