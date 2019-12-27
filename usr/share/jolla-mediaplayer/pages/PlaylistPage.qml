// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
import com.jolla.mediaplayer 1.0

Page {
    id: page

    property var media
    property bool isEditable: playlists.isEditable(media.url)

    Connections {
        target: playlists
        onUpdated: {
            if (playlistUrl == originalPlaylistModel.url) {
                originalPlaylistModel.clear()
                originalPlaylistModel.populate()
            }
        }
    }

    FilterModel {
        id: playlistModel
        sourceModel: originalPlaylistModel

        filterRegExp: RegExpHelpers.regExpFromSearchString(playlistHeader.searchText, true)
    }

    PlaylistModel {
        id: originalPlaylistModel
        url: media.url
        Component.onCompleted: populate()
    }

    MediaPlayerListView {
        id: view
        anchors.fill: parent
        model: playlistModel

        PullDownMenu {
            enabled: playlistModel.count > 0
            visible: playlistModel.count > 0

            MenuItem {
                //: Add to playing queue drop down menu item in playlist page
                //% "Add to playing queue"
                text: qsTrId("mediaplayer-me-playlist-add-to-playing-queue")
                onClicked: AudioPlayer.addToQueue(playlistModel)
            }

            MenuItem {
                //: Clear playlist drop down menu item in playlist page
                //% "Clear playlist"
                text: qsTrId("mediaplayer-me-playlist-clear-playlist")
                visible: isEditable
                onClicked: {
                    //: Clearing the playlist
                    //% "Clearing"
                    clearRemorse.execute(qsTrId("mediaplayer-la-clearing"), function() {
                        originalPlaylistModel.clear()
                        if (playlists.clearPlaylist(media, originalPlaylistModel)) {
                            pageStack.pop()
                        }
                    })
                }
            }

            NowPlayingMenuItem { }

            MenuItem {
                id: menuItemSearch

                //: Search menu entry
                //% "Search"
                text: qsTrId("mediaplayer-me-search")
                onClicked: playlistHeader.enableSearch()
                enabled: view.count > 0 || playlistHeader.searchText !== ''
            }
        }

        ViewPlaceholder {
            text: {
                if (playlistHeader.searchText !== '') {
                    //: Placeholder text for an empty search view
                    //% "No items found"
                    return qsTrId("mediaplayer-la-empty-search")
                } else {
                    //: "Placeholder text for an empty playlist; Add songs to playlist"
                    //% "Add some media"
                    return qsTrId("mediaplayer-la-add-some-media")
                }
            }
            enabled: playlistModel.count === 0
        }

        header: SearchPageHeader {
            id: playlistHeader
            width: parent.width

            title: media.title

            //: Playlist search field placeholder text
            //% "Search song"
            placeholderText: qsTrId("mediaplayer-tf-playlist-search")
        }

        delegate: MediaListDelegate {
            property int realIndex: playlistModel.mapRowToSource(index)

            formatFilter: playlistHeader.searchText

            function remove() {
                //: Delete a playlist item
                //% "Deleting"
                remorseAction( qsTrId("mediaplayer-la-deleting"), function() {
                    if (realIndex >= 0 ) {
                        originalPlaylistModel.remove(realIndex)
                        playlists.savePlaylist(page.media, originalPlaylistModel)
                    }
                })
            }

            menu: menuComponent
            onClicked: {
                AudioPlayer.play(view.model, index)
                playlists.updateAccessTime(page.media.url)
            }
            ListView.onRemove: animateRemoval()

            Component {
                id: menuComponent
                ContextMenu {
                    MenuItem {
                        //: Remove from playlist context menu item in playlist page
                        //% "Remove from playlist"
                        text: qsTrId("mediaplayer-me-playlist-remove-from-playlist")
                        onClicked: remove()
                    }
                }
            }
        }
    }

    RemorsePopup { id: clearRemorse }
}
