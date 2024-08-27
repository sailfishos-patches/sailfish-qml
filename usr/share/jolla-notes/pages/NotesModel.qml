import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import "notesdatabase.js" as Database

ListModel {
    id: model

    property string filter
    property bool populated
    property int moveCount: 1
    readonly property var availableColors: [
        "#cc0000", "#cc7700", "#ccbb00",
        "#88cc00", "#00b315", "#00bf9f",
        "#005fcc", "#0016de", "#bb00cc"]
    property var colorIndexConf: ConfigurationValue {
        key: "/apps/jolla-notes/next_color_index"
        defaultValue: 0
    }
    property var worker: WorkerScript {
        source: "notesmodel.js"
        onMessage: {
            if (messageObject.reply === "insert") {
                model.newNoteInserted()
            } else if (messageObject.reply == "update") {
                populated = true
            }
        }
    }
    signal newNoteInserted

    Component.onCompleted: {
        refresh()

        if (Database.migrated_color_index !== -1) {
            colorIndexConf.value = Database.migrated_color_index
        }
    }
    onFilterChanged: refresh()

    function refresh() {
        Database.updateNotes(filter, function (results) {
            var msg = {'action': 'update', 'model': model, 'results': results}
            worker.sendMessage(msg)
        })
    }

    function nextColor() {
        var index = colorIndexConf.value
        if (index >= availableColors.length)
            index = 0
        colorIndexConf.value = index + 1
        return availableColors[index]
    }

    function newNote(pagenr, initialtext, color) {
        var _color = color + "" // convert to string
        Database.newNote(pagenr, _color, initialtext)
        var msg = {'action': 'insert', 'model': model, "pagenr": pagenr, "text": initialtext, "color": _color }
        worker.sendMessage(msg)
    }

    function updateNote(idx, text) {
        Database.updateNote(get(idx).pagenr, text)
        var msg = {'action': 'textupdate', 'model': model, 'idx': idx, 'text': text}
        worker.sendMessage(msg)
    }

    function updateColor(idx, color) {
        var _color = color + "" // convert to string
        Database.updateColor(get(idx).pagenr, _color)
        var msg = {'action': 'colorupdate', 'model': model, 'idx': idx, 'color': _color}
        worker.sendMessage(msg)
    }

    function moveToTop(idx) {
        Database.moveToTop(get(idx).pagenr)
        var msg = {'action': 'movetotop', 'model': model, 'idx': idx}
        worker.sendMessage(msg)
        moveCount++
    }

    function deleteNote(idx) {
        Database.deleteNote(get(idx).pagenr)
        var msg = {'action': 'remove', 'model': model, "idx": idx}
        worker.sendMessage(msg)
    }
}
