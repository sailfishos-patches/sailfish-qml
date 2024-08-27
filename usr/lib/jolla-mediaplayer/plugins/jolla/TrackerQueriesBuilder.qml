// -*- qml -*-

import QtQuick 2.0
import com.jolla.mediaplayer 1.0

QtObject {
    id: trackerQueriesBuilder

    function getSongsQuery(searchText) {
        //: placeholder string for albums without a known name
        //% "Unknown album"
        var unknownAlbum = qsTrId("mediaplayer-la-unknown-album")

        //: placeholder string to be shown for media without a known artist
        //% "Unknown artist"
        var unknownArtist = qsTrId("mediaplayer-la-unknown-artist")

        return AudioTrackerHelpers.getSongsQuery(searchText, {"unknownArtist": unknownArtist, "unknownAlbum": unknownAlbum})
    }

    function getAlbumsQuery(searchText) {
        //: placeholder string to be shown for media without a known artist
        //% "Unknown artist"
        var unknownArtist = qsTrId("mediaplayer-la-unknown-artist")

        //: placeholder string for albums without a known name
        //% "Unknown album"
        var unknownAlbum = qsTrId("mediaplayer-la-unknown-album")

        //: string for albums with multiple artists
        //% "Multiple artists"
        var multipleArtists = qsTrId("mediaplayer-la-multiple-authors")

        return AudioTrackerHelpers.getAlbumsQuery(searchText,
            {"unknownArtist": unknownArtist,
             "unknownAlbum": unknownAlbum,
             "multipleArtists": multipleArtists})
    }

    function getArtistsQuery(searchText) {
        //: placeholder string to be shown for media without a known artist
        //% "Unknown artist"
        var unknownArtist = qsTrId("mediaplayer-la-unknown-artist")

        return AudioTrackerHelpers.getArtistsQuery(searchText, {"unknownArtist": unknownArtist})
    }
}
