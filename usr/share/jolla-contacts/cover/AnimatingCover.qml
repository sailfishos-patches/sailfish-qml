import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

Item {
    id: rootItem

    property bool active: root.active
    property int status: root.status
    property bool cacheSynchronized
    property real side: height / 2
    property real halfSide: height / 4
    property int duration: 500
    // Used to shift edges of avatar icons off the cover edge, prevents flickering
    property int edgeOffset: Theme.paddingSmall
    property bool ready: favoritesModel.populated && (status == Cover.Activating || status == Cover.Active)

    //+ Jonas Raoni Soares Silva
    //@ http://jsfromhell.com/array/shuffle [v1.0]
    function shuffle(o){ //v1.0
        for(var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
        return o;
    }
    function cacheFavorites() {

        // count the number of avatars
        var avatarCount = 0
        for (var i = 0; i < favoritesModel.count; i++) {
            var avatarUrl = favoritesModel.get(i).avatarUrl + ""
            if (avatarUrl.length > 0)  {
                avatarCount = avatarCount + 1
            }
        }

        var favoriteArray = []
        for (var i = 0; i < favoritesModel.count; i++) {
            var modelData = favoritesModel.get(i)

            // if there are enough avatars don't display name labels
            if (avatarCount < 4 || (modelData.avatarUrl + "").length > 0) {
                var personObject = {
                    "person": {
                        "primaryName": modelData.primaryName,
                        "secondaryName": modelData.secondaryName,
                        "avatarUrl": modelData.avatarUrl,
                        "displayLabel": modelData.displayLabel,
                        "presenceState": modelData.globalPresenceState
                    }
                }
                favoriteArray.push(personObject)
            }
        }

        favoriteArray = shuffle(favoriteArray)
        if (upperFavoritesModel.count > 0) {
            upperFavoritesModel.clear()
        }
        if (lowerFavoritesModel.count > 0) {
            lowerFavoritesModel.clear()
        }
        for (i = 0; i < favoriteArray.length; i++) {
            if (i % 2 === 0) {
                upperFavoritesModel.append(favoriteArray[i])
            } else {
                lowerFavoritesModel.append(favoriteArray[i])
            }
        }

        // 6 favorites are needed for smooth animation, fill models with empty
        // CoverContacts showing only background if we have less than 6 favorites.
        var fillerArray = []
        var contactCount = favoriteArray.length
        for (i = 1; i <= 6 - contactCount; i++) {
            personObject = {
                "person": {
                    "backgroundColor": Theme.highlightColor,
                    "backgroundOpacity": 0.1 * i,
                    "presenceState": Person.PresenceUnknown
                }
            }
            fillerArray.push(personObject)
        }
        fillerArray.sort(function() { return 0.5 - Math.random() })
        var index;
        for (i = 0; i < fillerArray.length; i++) {
            if (i % 2 === 0) {
                // Adding fillers to lowerFavoritesModel first is intentional to
                // balance the object count in both models.
                index = Math.round(Math.random() * lowerFavoritesModel.count)
                lowerFavoritesModel.insert(index, fillerArray[i])
            } else {
                index = Math.round(Math.random() * upperFavoritesModel.count)
                upperFavoritesModel.insert(index, fillerArray[i])
            }
        }
    }
    function loadCover() {
        if (favoritesModel.populated && !cacheSynchronized) {
            cacheSynchronized = true
            cacheFavorites()
        }
    }

    anchors.fill: parent
    onReadyChanged: if (ready) loadCover()
    Component.onCompleted: loadCover()

    PathView {
        id : upperFavorites

        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: parent.height/2
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: duration
        model: ListModel { id: upperFavoritesModel }
        delegate: CoverContact { height: side; width: height; contact: person }
        path: Path {
            startX: root.width + halfSide + edgeOffset; startY: halfSide
            PathLine { x: root.width - halfSide + edgeOffset; y: halfSide }
            PathLine { x: root.width - (upperFavoritesModel.count - 1) * side - halfSide + edgeOffset; y: halfSide }
        }
    }

    PathView {
        id: lowerFavorites

        anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
        height: parent.height/2
        highlightRangeMode: PathView.StrictlyEnforceRange
        highlightMoveDuration: duration
        model: ListModel { id: lowerFavoritesModel }
        delegate: CoverContact { height: side; width: height; contact: person }
        path: Path {
            startX: -halfSide - edgeOffset; startY: halfSide
            PathLine { x: halfSide - edgeOffset; y: halfSide }
            PathLine { x: side * (lowerFavoritesModel.count - 1) + halfSide - edgeOffset; y: halfSide }
        }
    }

    Timer {
        property bool upper: true;
        interval: 4000
        repeat: true
        running: active
        onTriggered: {
            if (upper) {
                upperFavorites.decrementCurrentIndex()
            } else {
                lowerFavorites.decrementCurrentIndex()
            }
            upper = !upper
        }
    }

    Connections {
        target: favoritesModel
        onDataChanged: rootItem.cacheSynchronized = false
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-search"
            onTriggered: {
                app.openSearch()
            }
        }
    }
}
