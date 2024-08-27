// Copyright (C) 2012-2013 Jolla Ltd.
// Contact: Richard Braakman <richard.braakman@jollamobile.com>

// The page numbers in the db must stay sequential (starting from 1),
// but the page numbers in the model may have gaps if the filter is active.
// The page numbers in the model must still be ascending, though.

// The details depend on Qt's openDatabaseSync implementation, but
// the data will probably be stored in an sqlite file under
//   $HOME/.local/share/jolla-notes/QML/OfflineStorage/Databases/

.import QtQuick.LocalStorage 2.0 as Sql

var migrated_color_index = -1

function _rawOpenDb() {
    return Sql.LocalStorage.openDatabaseSync('silicanotes', '', 'Notes', 10000)
}

function upgradeSchema(db) {
    // Awkward. db.changeVersion does NOT update db.version, but DOES
    // check that db.version is equal to the first parameter.
    // So reopen the database after every changeVersion to get the
    // updated db.version.
    if (db.version == '') {
        // Change the version directly to '3', no point creating the
        // now obsolete next_color_index table and drop it immediately
        // after that.
        db.changeVersion('', '3', function (tx) {
            tx.executeSql(
                'CREATE TABLE notes (pagenr INTEGER, color TEXT, body TEXT)')
        })
        db = _rawOpenDb()
    }
    if (db.version == '1') {
        // Version '1' equals to version '3'. Just change the version number.
        // Old migration code to version '2' left in comments for reference.
        db.changeVersion('1', '3')
        /*
        db.changeVersion('1', '2', function (tx) {
            tx.executeSql('CREATE TABLE next_color_index (value INTEGER)')
            tx.executeSql('INSERT INTO next_color_index VALUES (0)')
        })
        */
        db = _rawOpenDb()
    }
    if (db.version == '2') {
        db.changeVersion('2', '3', function (tx) {
            // "next_color_index" table may be missing because it was never backed up.
            var results = tx.executeSql('SELECT name FROM sqlite_master WHERE type="table" AND name="next_color_index"');
            if (results.rows.length) {
                var r = tx.executeSql('SELECT value FROM next_color_index LIMIT 1')
                migrated_color_index = parseInt(r.rows.item(0).value, 10)
                // next_color_index is stored in dconf from now on. Drop the table.
                tx.executeSql('DROP TABLE next_color_index')
            }
        })
        db = _rawOpenDb()
    }
}

function openDb() {
    var db = _rawOpenDb()
    if (db.version != '3')
        upgradeSchema(db)
    return db
}

var regex = new RegExp(/['\%\\\_]/g)
var escaper = function escaper(char){
    var m = ["'", "%", "_", "\\"]
    var r = ["''", "\\%", "\\_", "\\\\"]
    return r[m.indexOf(char)]
}

function updateNotes(filter, callback) {
    var db = openDb()
    db.readTransaction(function (tx) {
        var results
        if (filter.length > 0) {
            results = tx.executeSql("SELECT pagenr, color, body FROM notes WHERE body LIKE '%" + filter.replace(regex, escaper) + "%' ESCAPE '\\' ORDER BY pagenr")
        } else {
            results = tx.executeSql("SELECT pagenr, color, body FROM notes ORDER BY pagenr")
        }

        var array = []
        for (var i = 0; i < results.rows.length; i++) {
            var item = results.rows.item(i)
            array[i] = {
                "pagenr": item.pagenr,
                "text": item.body,
                "color": item.color
            }
        }

        callback(array)
    })
}

function newNote(pagenr, color, initialtext) {
    var db = openDb()
    db.transaction(function (tx) {
        tx.executeSql('UPDATE notes SET pagenr = pagenr + 1 WHERE pagenr >= ?',
                      [pagenr])
        tx.executeSql('INSERT INTO notes (pagenr, color, body) VALUES (?, ?, ?)',
                      [pagenr, color, initialtext])
    })
}

function updateNote(pagenr, text) {
    var db = openDb()
    db.transaction(function (tx) {
        tx.executeSql('UPDATE notes SET body = ? WHERE pagenr = ?',
                      [text, pagenr])
    })
}

function updateColor(pagenr, color) {
    var db = openDb()
    db.transaction(function (tx) {
        tx.executeSql('UPDATE notes SET color = ? WHERE pagenr = ?',
                      [color, pagenr])
    })
}

function moveToTop(pagenr) {
    var db = openDb()
    db.transaction(function (tx) {
        // Use modulo-pagenr arithmetic to rotate the page numbers: add 1 to
        // all of them except pagenr itself, which goes to 1.
        tx.executeSql('UPDATE notes SET pagenr = (pagenr % ?) + 1 WHERE pagenr <= ?',
                      [pagenr, pagenr])
    })
}

function deleteNote(pagenr) {
    var db = openDb();
    db.transaction(function (tx) {
        tx.executeSql('DELETE FROM notes WHERE pagenr = ?', [pagenr])
        tx.executeSql('UPDATE notes SET pagenr = pagenr - 1 WHERE pagenr > ?',
                      [pagenr])
    })
}
