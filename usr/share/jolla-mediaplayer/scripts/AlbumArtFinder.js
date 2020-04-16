.pragma library

var _reservedOrInvalid = {}

function randomArt(model, albumArtProvider) {
    var randomIndex = Math.floor(Math.random() * model.count)
    var i = randomIndex
    var count = model.count
    var textualArt
    // From index to end as index is a random model index
    while (i < count) {
        var song = model.get(i)
        if (!_reservedOrInvalid[song.album + song.author]) {
            var image = albumArtProvider.albumThumbnail(song.album, song.author)
            _reservedOrInvalid[song.album + song.author] = true
            if (image != "") {
                return {
                    url: image,
                    author: song.author,
                    title: song.title
                }
            }
        } else if (!textualArt) {
            textualArt = {
                url: image,
                author: song.author,
                title: song.title
            }
        }
        ++i
    }

    // From beginning to index as index is a random model index
    i = 0
    count = randomIndex
    while (i < count) {
        song = model.get(i)
        if (!_reservedOrInvalid[song.album + song.author]) {
            image = albumArtProvider.albumThumbnail(song.album, song.author)
            _reservedOrInvalid[song.album + song.author] = true
            if (image != "") {
                return {
                    url: image,
                    author: song.author,
                    title: song.title
                }
            }
        } else if (!textualArt) {
            textualArt = {
                url: image,
                author: song.author,
                title: song.title
            }
        }
        ++i
    }

    return textualArt ? textualArt : { url : "", album: "", author: ""}
}
