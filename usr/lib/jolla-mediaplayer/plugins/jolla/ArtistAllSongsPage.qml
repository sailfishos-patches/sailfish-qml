// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
import com.jolla.mediaplayer 1.0

Page {
    property var media

    MediaPlayerListView {
        id: view

        model: GriloTrackerModel {
            query: {
                //: placeholder string for albums without a known name
                //% "Unknown album"
                var unknownAlbum = qsTrId("mediaplayer-la-unknown-album")

                //: placeholder string to be shown for media without a known artist
                //% "Unknown artist"
                var unknownArtist = qsTrId("mediaplayer-la-unknown-artist")

                return AudioTrackerHelpers.getSongsQuery(artistHeader.searchText,
                                                         {"unknownArtist": unknownArtist,
                                                             "unknownAlbum": unknownAlbum,
                                                             "authorId": media.id})
            }
        }

        PullDownMenu {
            MenuItem {
                //: Shuffle all menu entry in artist page
                //% "Shuffle all"
                text: qsTrId("mediaplayer-me-artist-shuffle-all")
                onClicked: AudioPlayer.shuffleAndPlay(view.model, view.count)
            }

            NowPlayingMenuItem { }

            MenuItem {
                //: Search menu entry
                //% "Search"
                text: qsTrId("mediaplayer-me-search")
                onClicked: artistHeader.enableSearch()
                enabled: view.count > 0 || artistHeader.searchText !== ''
            }
        }

        ViewPlaceholder {
            //: Placeholder text for an empty search view
            //% "No items found"
            text: qsTrId("mediaplayer-la-empty-search")
            enabled: view.count === 0 && !busyIndicator.running
        }

        PageBusyIndicator {
            id: busyIndicator

            running: view.model.source.fetching
        }

        Component {
            id: addPageComponent
            AddToPlaylistPage { }
        }

        header: SearchPageHeader {
            id: artistHeader
            width: parent.width

            //: placeholder text if we don't know the artist name
            //% "Unknown artist"
            title: media.title != "" ? media.title : qsTrId("mediaplayer-la-unknown-artist")

            //: Artist all songs search field placeholder text
            //% "Search song"
            placeholderText: qsTrId("mediaplayer-tf-songs-search")
        }

        delegate: MediaListDelegate {
            id: delegate

            property var itemMedia: media

            formatFilter: artistHeader.searchText

            function remove() {
                AudioPlayer.remove(itemMedia, delegate, playlists)
            }

            menu: menuComponent
            onClicked: AudioPlayer.play(view.model, index)

            ListView.onAdd: AddAnimation { target: delegate }
            ListView.onRemove: animateRemoval()

            Component {
                id: menuComponent
                ContextMenu {
                    MenuItem {
                        //: Add to playlist context menu item in artist page
                        //% "Add to playlist"
                        text: qsTrId("mediaplayer-me-artist-add-to-playlist")
                        onClicked: pageStack.animatorPush(addPageComponent, {media: itemMedia})
                    }
                    MenuItem {
                        //: Add to playing queue context menu item in artist page
                        //% "Add to playing queue"
                        text: qsTrId("mediaplayer-me-artist-add-to-playing-queue")
                        onClicked: AudioPlayer.addToQueue(itemMedia)
                    }
                    MenuItem {
                        //: Delete item
                        //% "Delete"
                        text: qsTrId("mediaplayer-me-all-songs-delete")
                        onClicked: remove()
                    }
                }
            }
        }
    }
}
