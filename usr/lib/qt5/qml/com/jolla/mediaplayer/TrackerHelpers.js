.pragma library
.import "RegExpHelpers.js" as RegExpHelpers

function escapeSparql(string) {
    if (string == undefined) {
        return ""
    }

    // As described at http://www.w3.org/TR/rdf-sparql-query/#grammarEscapes
    string = string.replace("\\", "\\\\")
    .replace("\t", "\\t")
    .replace("\n", "\\n")
    .replace("\r", "\\r")
    .replace("\b", "\\b")
    .replace("\f", "\\f")
    .replace("\"", "\\\"")
    .replace("'", "\\'")
    return string
}

function getSearchFilter(searchText, variable) {
    // Emacs search style: only be case sensitive if there are capitals.
    var rule = ""
    if (searchText == searchText.toLowerCase()) {
        rule = "regex(%1, \"%2\", \"i\")".arg(variable).arg(escapeSparql(RegExpHelpers.escapeRegExp(searchText)))
    } else {
        rule = "fn:contains(%1, \"%2\")".arg(variable).arg(escapeSparql(searchText))
    }

    return " FILTER (%1) ".arg(rule)
}
