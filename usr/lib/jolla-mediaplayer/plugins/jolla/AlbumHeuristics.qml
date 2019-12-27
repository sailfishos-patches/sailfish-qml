// -*- qml -*-

import QtQuick 2.0

QtObject {
    function guessAuthor(author, count) {
        // TODO: test how this will behave if we have 1 mp3 files with similar album
        // and one of them has no artist.
        if (count == 0 || author == "") {
            //: placeholder string for albums without a known artist
            //% "Unknown artist"
            return qsTrId("mediaplayer-la-unknown-author")
        } else if (count == 1) {
            return author
        } else {
            //: string for albums with multiple artists
            //% "Multiple artists"
            return qsTrId("mediaplayer-la-multiple-authors")
        }
    }
}
