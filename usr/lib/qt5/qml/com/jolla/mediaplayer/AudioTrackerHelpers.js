.pragma library
.import "RegExpHelpers.js" as RegExpHelpers
.import "TrackerHelpers.js" as TrackerHelpers
.import org.nemomobile.grilo 0.1 as Grilo

// The columns matching grilo column names, see grl-tracker-source-api.c.
// First is media type as int matching grilo media type enum

// %1 unknown artist string
// %2 unknown album string
// %3 extra inner rules
// %4 extra outer rules
var songsQuery = "" +
        "SELECT " +
        Grilo.GriloMedia.TypeAudio + " AS ?type" +
        "  ?song AS ?id " +
        "  ?url " +
        "  ?duration " +
        "  ?author " +
        "  ?title " +
        "  ?album " +
        "WHERE { SERVICE <dbus:org.freedesktop.Tracker3.Miner.Files> {" +
        "  GRAPH tracker:Audio { " +
        "    SELECT ?song ?url " +
        "      nfo:duration(?song) AS ?duration " +
        "      tracker:coalesce(nmm:artistName(nmm:artist(?song)), \"%1\") AS ?author " +
        "      tracker:coalesce(nie:title(?song), tracker:string-from-filename(?filename)) AS ?title " +
        "      tracker:coalesce(nie:title(nmm:musicAlbum(?song)), \"%2\") AS ?album " +
        "      nmm:setNumber(nmm:musicAlbumDisc(?song)) AS ?setnumber " +
        "      nmm:trackNumber(?song) AS ?tracknumber " +
        "    WHERE { " +
        "      ?song a nmm:MusicPiece ; " +
        "           nie:isStoredAs ?url . " +
        "      ?url nfo:fileName ?filename . " +
        "      ?url nie:dataSource/tracker:available true . " +
        "      %3 " +
        "    } " +
        "  } } "

function getSongsQuery(aSearchText, opts) {
    var unknownArtistText = "unknownArtist" in opts ? TrackerHelpers.escapeSparql(opts["unknownArtist"]) : "Unknown artist"
    var unknownAlbumText = "unknownAlbum" in opts ? TrackerHelpers.escapeSparql(opts["unknownAlbum"]) : "Unknown album"
    var artistId = "authorId" in opts ? TrackerHelpers.escapeSparql(opts["authorId"]) : ""
    var albumId = "albumId" in opts ? TrackerHelpers.escapeSparql(opts["albumId"]) : ""

    var extraRules = ""
    if (albumId != "") {
        if (albumId == "0") {
            // special case for unknown album
            extraRules = "FILTER NOT EXISTS { ?song nmm:musicAlbum ?anyAlbum } "
        } else {
            extraRules = "?song nmm:musicAlbum \"%1\" . ".arg(albumId)
        }
    }

    if (artistId != "") {
        if (artistId == "0") {
            // unknown artist
            extraRules += "FILTER NOT EXISTS { ?song nmm:artist ?anyArtist } "
        } else {
            extraRules += "?song nmm:artist \"%1\" . ".arg(artistId)
        }
    }

    var extraOuterRules = ""
    if (aSearchText != "") {
        extraOuterRules += TrackerHelpers.getSearchFilter(aSearchText, "?title")
    }

    var orderRule = ""
    if (albumId != "") {
        orderRule = "" +
                "ORDER BY " +
                "  ASC(?setnumber) " +
                "  ASC(?tracknumber) " +
                "  ASC(fn:lower-case(?title)) "
    } else {
        orderRule = "" +
                "ORDER BY " +
                "  ASC(fn:lower-case(?author)) " +
                "  ASC(fn:lower-case(?album)) " +
                "  ASC(?setnumber) " +
                "  ASC(?tracknumber) " +
                "  ASC(fn:lower-case(?title)) "
    }

    return songsQuery.arg(unknownArtistText).arg(unknownAlbumText).arg(extraRules) + extraOuterRules + " } " + orderRule
}

// We are resolving several times "nmm:performer" and "nmm:musicAlbum"
// as a property functions in the "SELECT" side instead of using the
// "OPTIONAL" keyword in the "WHERE" part. In terms of performance, it
// is better to use property functions than the "OPTIONAL" keyword, as
// explained at:
// https://wiki.gnome.org/Projects/Tracker/Documentation/SparqlTipsTricks#Use_property_functions
//
// We are using this strategy also in other similar queries.

// We are "overloading" tracker-urn to hold the artists id

// %1 tracker_urn
// %2 unknown artist name string
// %3 multiple artists text
// %4 unknown album text
// %5 extra inner rules
// %6 extra outer rules
var albumsQuery = "" +
        "SELECT " +
        Grilo.GriloMedia.TypeContainer + " AS ?type " +
        "  ?album as ?id " +
        "  ?title " +
        "  ?author " +
        "  ?childcount " +
        "  \"%1\" AS ?tracker_urn " +
        "WHERE { SERVICE <dbus:org.freedesktop.Tracker3.Miner.Files> {" +
        "  GRAPH tracker:Audio { " +
        "    SELECT " +
        "      tracker:coalesce(nmm:musicAlbum(?song), 0) as ?album " +
        "      tracker:coalesce(nie:title(nmm:musicAlbum(?song)), \"%4\") AS ?title " +
        "      IF(COUNT(DISTINCT(tracker:coalesce(nmm:artist(?song), 0))) > 1, " +
        "         \"%3\", tracker:coalesce(nmm:artistName(nmm:artist(?song)), \"%2\"))" +
        "      AS ?author " +
        "      COUNT(DISTINCT(?song)) AS ?childcount " +
        "    WHERE { " +
        "      ?song a nmm:MusicPiece ; " +
        "            nie:isStoredAs ?file . " +
        "      ?file nie:dataSource/tracker:available true . " +
        "      %5" +
        "    } " +
        "    GROUP BY ?album " +
        "  } } " +
        "  %6 " +
        "} " +
        "ORDER BY " +
        "  ASC(fn:lower-case(?author)) " +
        "  ASC(fn:lower-case(?title)) "

function getAlbumsQuery(aSearchText, opts) {
    var artistId = "authorId" in opts ? TrackerHelpers.escapeSparql(opts["authorId"]) : ""
    var unknownArtistText = "unknownArtist" in opts ? TrackerHelpers.escapeSparql(opts["unknownArtist"]) : "Unknown artist"
    var multipleArtistsText = "multipleArtists" in opts ? TrackerHelpers.escapeSparql(opts["multipleArtists"]) : "Multiple artists"
    var unknownAlbumText = "unknownAlbum" in opts ? TrackerHelpers.escapeSparql(opts["unknownAlbum"]) : "Unknown album"
    var extraRules = ""
    if (artistId != "") {
        if (artistId == "0") {
            // special case for unknown artist
            extraRules += "FILTER NOT EXISTS { ?song nmm:artist ?anyArtist }"
        } else {
            extraRules += "?song nmm:artist \"%1\" . ".arg(artistId)
        }
    }

    var extraOuterRules = ""
    if (aSearchText != "") {
        extraOuterRules = TrackerHelpers.getSearchFilter(aSearchText, "?title")
    }

    return albumsQuery.arg(artistId).arg(unknownArtistText).arg(multipleArtistsText).arg(unknownAlbumText).arg(extraRules).arg(extraOuterRules)
}


// We are "overloading" childcount to hold the total duration. Just think
// our container as a container of seconds and then all that would start to make sense :P
// %1 = unknown artist text
// %2 = extra filters
var artistsQuery = "" +
        "SELECT " +
        Grilo.GriloMedia.TypeContainer + " AS ?type " +
        "  ?artist AS ?id " +
        "  ?title " +
        "  ?childcount " +
        "WHERE { SERVICE <dbus:org.freedesktop.Tracker3.Miner.Files> {" +
        "  GRAPH tracker:Audio { " +
        "    SELECT " +
        "      tracker:coalesce(nmm:albumArtist(nmm:musicAlbum(?song)), nmm:artist(?song), 0) AS ?artist " +
        "      tracker:coalesce(nmm:artistName(nmm:albumArtist(nmm:musicAlbum(?song))), nmm:artistName(nmm:artist(?song))) AS ?artistName " +
        "      tracker:coalesce(nmm:artistName(nmm:albumArtist(nmm:musicAlbum(?song))), nmm:artistName(nmm:artist(?song)), \"%1\") AS ?title" +
        "      SUM(nfo:duration(?song)) AS ?childcount " +
        "    WHERE { " +
        "      ?song a nmm:MusicPiece ; " +
        "            nie:isStoredAs ?file . " +
        "      ?file nie:dataSource/tracker:available true . " +
        "    } " +
        "    GROUP BY ?artist " +
        "  } } " +
        "  %2 " +
        "} " +
        "ORDER BY ASC(fn:lower-case(?title))"

function getArtistsQuery(aSearchText, opts) {
    var unknownArtistText = "unknownArtist" in opts ? TrackerHelpers.escapeSparql(opts["unknownArtist"]) : "Unknown artist"
    var extraRules = ""

    if (aSearchText != "") {
        extraRules = TrackerHelpers.getSearchFilter(aSearchText, "?artistName")
    }

    return artistsQuery.arg(unknownArtistText).arg(extraRules)
}
