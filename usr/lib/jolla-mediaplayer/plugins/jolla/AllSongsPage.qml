// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.mediaplayer 1.0

Page {
    id: allSongsPage

    property var model
    property string searchText

    TrackerQueriesBuilder {
        id: queriesBuilder
    }

    MediaPlayerListView {
        id: view

        property string query: queriesBuilder.getSongsQuery(allSongsHeader.searchText)

        model: allSongsPage.model

        Binding {
            target: allSongsPage.model.source
            property: "query"
            value: view.query
        }

        PullDownMenu {

            MenuItem {
                //: Shuffle all menu entry in all songs page
                //% "Shuffle all"
                text: qsTrId("mediaplayer-me-all-songs-shuffle-all")
                onClicked: AudioPlayer.shuffleAndPlay(view.model, view.count)
            }

            NowPlayingMenuItem { }

            MenuItem {
                id: menuItemSearch

                //: Search menu entry
                //% "Search"
                text: qsTrId("mediaplayer-me-search")
                onClicked: allSongsHeader.enableSearch()
                enabled: view.count > 0 || allSongsHeader.searchText !== ''
            }
        }

        Component {
            id: addPageComponent
            AddToPlaylistPage { }
        }

        ViewPlaceholder {
            text: {
                if (allSongsHeader.searchText !== '') {
                    //: Placeholder text for an empty search view
                    //% "No items found"
                    return qsTrId("mediaplayer-la-empty-search")
                } else {
                    //: Placeholder text for an empty view
                    //% "Get some media"
                    return qsTrId("mediaplayer-la-get-some-media")
                }
            }
            enabled: view.count === 0
        }

        header: SearchPageHeader {
            id: allSongsHeader
            width: parent.width

            //: Title for the all songs page
            //% "All songs"
            title: qsTrId("mediaplayer-he-all-songs")

            //: All songs search field placeholder text
            //% "Search song"
            placeholderText: qsTrId("mediaplayer-tf-songs-search")

            searchText: allSongsPage.searchText
            Component.onCompleted: if (searchText !== '') enableSearch()
        }

        delegate: MediaListDelegate {
            id: delegate

            property var itemMedia: media

            formatFilter: allSongsHeader.searchText

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

            menu: menuComponent
            onClicked: AudioPlayer.play(view.model, index)

            ListView.onAdd: AddAnimation { target: delegate }
            ListView.onRemove: animateRemoval()

            Component {
                id: menuComponent
                ContextMenu {
                    MenuItem {
                        //: Add to playlist context menu item in all songs page
                        //% "Add to playlist"
                        text: qsTrId("mediaplayer-me-all-songs-add-to-playlist")
                        onClicked: pageStack.animatorPush(addPageComponent, {media: itemMedia})
                    }
                    MenuItem {
                        //: Add to playing queue context menu item in all songs page
                        //% "Add to playing queue"
                        text: qsTrId("mediaplayer-me-all-songs-add-to-playing-queue")
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
