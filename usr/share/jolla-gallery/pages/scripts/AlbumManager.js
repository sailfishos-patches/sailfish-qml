// Emulate a module api from Qt5 using a singleton instance of a type.

.pragma library
.import QtQuick 2.1 as QtQuick

var _albumManagerComponent
var _albumManagerInstance

function albumManager() {
    if (_albumManagerComponent === undefined) {
        _albumManagerComponent = Qt.createComponent(Qt.resolvedUrl('../PhotoAlbumManager.qml'))
        if (_albumManagerComponent.status !== QtQuick.Component.Ready) {
            console.error("unable to create album manager component", _albumManagerComponent.errorString())
            return undefined
        }

        _albumManagerInstance = _albumManagerComponent.createObject(0)
    }
    return _albumManagerInstance
}

function trackerIdFromGalleryId(albumId) {
    return "<" + albumId.substring(12) + ">"
}

function addToAlbum(albumId, imageUrl) {
    var manager = albumManager()
    manager.addToAlbum(albumId, imageUrl)
}

function removeFromAlbum(albumId, imageUrl) {
    var manager = albumManager()
    manager.removeFromAlbum(albumId, imageUrl)
}

function createAlbum(albumId, title, imageUrls) {
    var manager = albumManager()
    manager.createAlbum(albumId, title, imageUrls)
}

function createAnonymousAlbum(title, imageUrls) {
    var manager = albumManager()
    manager.createAlbum("_:x", title, imageUrls)
}

function removeAlbum(albumId) {
    var manager = albumManager()
    manager.removeAlbum(albumId)
}


function deleteMedia(url) {
    var manager = albumManager()
    manager.deleteMedia(url)
}
