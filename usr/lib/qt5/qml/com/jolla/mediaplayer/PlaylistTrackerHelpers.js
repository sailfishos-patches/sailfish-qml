.pragma library
.import "RegExpHelpers.js" as RegExpHelpers
.import "TrackerHelpers.js" as TrackerHelpers
.import org.nemomobile.grilo 0.1 as Grilo

// %1 = extra inner rules
// %2 = extra outer rules
var playlistsQuery = "" +
        "SELECT " +
        Grilo.GriloMedia.TypeContainer + " AS ?type " +
        "  ?urn AS ?id " +
        "  ?url " +
        "  ?title " +
        "  ?childcount " +
        "WHERE { SERVICE <dbus:org.freedesktop.Tracker3.Miner.Files> {" +
        "  GRAPH tracker:Audio { " +
        "    SELECT ?urn ?url " +
        "      tracker:coalesce(nie:title(?urn), tracker:string-from-filename(nfo:fileName(?url))) AS ?title " +
        "      tracker:coalesce(nfo:entryCounter(?urn), 0) AS ?childcount " +
        "      nie:contentAccessed(?urn) AS ?contentAccessed " +
        "    WHERE { " +
        "      ?urn a nmm:Playlist ; " +
        "           nie:isStoredAs ?url . " +
        "      ?url nie:dataSource/tracker:available true . " +
        "      %1 " +
        "    } " +
        "  } }" +
        "  %2 " +
        "}"

function getPlaylistsQuery(aSearchText, opts) {
    var location = "location" in opts ? opts["location"] : ""
    var editablePlaylistsOnly = "editablePlaylistsOnly" in opts ? opts["editablePlaylistsOnly"] : false
    var sortByUsage = "sortByUsage" in opts ? opts["sortByUsage"] : false

    // The entry counter because playlist removal has a hack for setting counter -1
    var extraInnerRules = ""
    if (editablePlaylistsOnly) {
        extraInnerRules = " FILTER ((nfo:entryCounter(?urn) >= 0 || !bound(nfo:entryCounter(?urn))) && fn:ends-with(?url, \".pls\") ) "
    } else {
        extraInnerRules = " FILTER ( (nfo:entryCounter(?urn) >= 0 || !bound(nfo:entryCounter(?urn))) ) "
    }

    var extraOuterRules = ""
    if (aSearchText != "") {
        extraOuterRules = TrackerHelpers.getSearchFilter(aSearchText, "?title")
    }

    if (location != "") {
        extraOuterRules += " FILTER (tracker:uri-is-descendant(\"file://%1\", ?url) ) ".arg(TrackerHelpers.escapeSparql(location))
    }

    var orderByRule = ""
    if (sortByUsage) {
        // contentAccessed inserted only by us
        orderByRule = " ORDER BY DESC(?contentAccessed)"
    } else {
        orderByRule = " ORDER BY ASC(fn:lower-case(?title))"
    }

    return playlistsQuery.arg(extraInnerRules).arg(extraOuterRules) + orderByRule
}
