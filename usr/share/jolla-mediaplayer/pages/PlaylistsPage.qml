// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
import com.jolla.mediaplayer 1.0

Page {
    id: playlistsPage

    property string searchText

    MediaPlayerListView {
        id: view

        anchors.fill: parent
        model: GriloTrackerModel {
            id: playlistModel
            query: PlaylistTrackerHelpers.getPlaylistsQuery(playlistsHeader.searchText, {})
        }

        Connections {
            target: playlists
            onUpdated: playlistModel.refresh()
        }

        PullDownMenu {

            MenuItem {
                //: Menu label for adding a new playlist
                //% "New playlist"
                text: qsTrId("mediaplayer-me-new-playlist")
                onClicked: pageStack.animatorPush("com.jolla.mediaplayer.NewPlaylistDialog", {})
            }

            NowPlayingMenuItem { }

            MenuItem {
                //: Search menu entry
                //% "Search"
                text: qsTrId("mediaplayer-me-search")
                onClicked: playlistsHeader.enableSearch()
                enabled: view.count > 0 || playlistsHeader.searchText !== ''
            }
        }

        header: SearchPageHeader {
            id: playlistsHeader

            width: parent.width

            //: page header for the playlists page
            //% "Playlists"
            title: qsTrId("mediaplayer-he-playlists")

            //: Playlists search field placeholder text
            //% "Search playlist"
            placeholderText: qsTrId("mediaplayer-tf-playlists-search")

            searchText: playlistsPage.searchText
            Component.onCompleted: if (searchText !== '') enableSearch()
        }

        delegate: MediaContainerPlaylistDelegate {
            formatFilter: playlistsHeader.searchText
            color: model.title != "" ? PlaylistColors.nameToColor(model.title)
                                     : "transparent"
            highlightColor: model.title != "" ? PlaylistColors.nameToHighlightColor(model.title)
                                              : "transparent"
            title: media.title
            songCount: media.childCount
            menu: menuComponent

            // FIXME: makes the transparent color show up briefly
            ListView.onRemove: animateRemoval()
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("PlaylistPage.qml"), {media: media})

            function remove() {
                remorseDelete(function() { playlists.removePlaylist(media) })
            }

            Component {
                id: menuComponent
                ContextMenu {
                    MenuItem {
                        //% "Delete"
                        text: qsTrId("mediaplayer-me-delete")
                        onClicked: remove()
                    }
                }
            }
        }

        ViewPlaceholder {
            text: {
                if (playlistsHeader.searchText !== '') {
                    //: Placeholder text for an empty search view
                    //% "No items found"
                    return qsTrId("mediaplayer-la-empty-search")
                } else {
                    //: Placeholder text for an empty playlists view
                    //% "Create a playlist"
                    return qsTrId("mediaplayer-la-create-a-playlist")
                }
            }
            enabled: view.count === 0 && !busyIndicator.running
        }

        PageBusyIndicator {
            id: busyIndicator

            running: playlistModel.fetching
        }
    }
}
