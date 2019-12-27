// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
import com.jolla.mediaplayer 1.0

Page {
    id: albumPage

    property var media

    Loader {
        id: coverLoader

        active: albumPage.isLandscape && coverArt.source != ""
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.horizontalCenter
            right: parent.right
        }

        Component.onCompleted: setSource("CoverArtHolder.qml", { "view": view, "coverArt": coverArt })
    }

    CoverArt {
        id: coverArt

        source: albumArtProvider.albumArt(media.title, media.author)
    }

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

                // tracker-urn is abused with the id of the author
                return AudioTrackerHelpers.getSongsQuery(albumHeader.searchText,
                                                         {"unknownArtist": unknownArtist,
                                                             "unknownAlbum": unknownAlbum,
                                                             "authorId": media.get("tracker-urn"),
                                                             "albumId": media.id})
            }
        }

        contentWidth: albumPage.width

        PullDownMenu {
            id: album

            MenuItem {
                //: Shuffle all menu entry in album page
                //% "Shuffle all"
                text: qsTrId("mediaplayer-me-album-shuffle-all")
                onClicked: AudioPlayer.shuffleAndPlay(view.model, view.count)
            }

            NowPlayingMenuItem { }

            MenuItem {
                id: menuItemSearch

                //: Search menu entry
                //% "Search"
                text: qsTrId("mediaplayer-me-search")
                onClicked: albumHeader.enableSearch()
                enabled: view.count > 0 || albumHeader.searchText !== ''
            }
        }

        ViewPlaceholder {
            //: Placeholder text for an empty search view
            //% "No items found"
            text: qsTrId("mediaplayer-la-empty-search")
            enabled: view.count === 0
        }

        Component {
            id: addPageComponent
            AddToPlaylistPage { }
        }

        header: SearchPageHeader {
            id: albumHeader
            width: albumPage.isLandscape ? view.contentWidth : view.width

            //: header for the page showing the songs that don't belong to a known album
            //% "Unknown album"
            title: media.title !== "" ? media.title : qsTrId("mediaplayer-la-unknown-album")

            //: All songs search field placeholder text
            //% "Search song"
            placeholderText: qsTrId("mediaplayer-tf-album-search")

            coverArt: albumPage.isLandscape ? null : coverArt
        }

        delegate: MediaListDelegate {
            id: delegate

            property var itemMedia: media

            formatFilter: albumHeader.searchText
            menu: menuComponent
            onClicked: AudioPlayer.play(view.model, index)

            ListView.onAdd: AddAnimation { target: delegate }
            ListView.onRemove: animateRemoval()

            function remove() {
                //: Deleting in n seconds
                //% "Deleting"
                remorseAction(qsTrId("mediaplayer-la-deleting"), function() {
                    if (File.removeFile(itemMedia.url)) {

                        // Remove item from the playqueue
                        AudioPlayer.removeItemFromQueue(itemMedia)

                        // Remove the item from the playlists
                        playlists.removeItem(itemMedia.url)
                    }
                })
            }

            Component {
                id: menuComponent

                ContextMenu {

                    width: view.contentWidth

                    MenuItem {
                        //: Add to playlist context menu item in album page
                        //% "Add to playlist"
                        text: qsTrId("mediaplayer-me-album-add-to-playlist")
                        onClicked: pageStack.animatorPush(addPageComponent, {media: itemMedia})
                    }
                    MenuItem {
                        //: Add to playing queue context menu item in album page
                        //% "Add to playing queue"
                        text: qsTrId("mediaplayer-me-album-add-to-playing-queue")
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
