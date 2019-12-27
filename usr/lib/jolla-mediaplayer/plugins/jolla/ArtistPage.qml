// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
import com.jolla.mediaplayer 1.0
import org.nemomobile.thumbnailer 1.0

Page {
    id: artistAlbumsPage

    property var media

    AlbumHeuristics {
        id: heuristics
    }

    MediaPlayerListView {
        id: view

        model: GriloTrackerModel {
            query: {
                //: placeholder string to be shown for media without a known artist
                //% "Unknown artist"
                var unknownArtist = qsTrId("mediaplayer-la-unknown-artist")

                //: placeholder string for albums without a known name
                //% "Unknown album"
                var unknownAlbum = qsTrId("mediaplayer-la-unknown-album")

                //: string for albums with multiple artists
                //% "Multiple artists"
                var multipleArtists = qsTrId("mediaplayer-la-multiple-authors")

                return AudioTrackerHelpers.getAlbumsQuery(albumsHeader.searchText,
                                                          {"unknownArtist": unknownArtist,
                                                              "unknownAlbum": unknownAlbum,
                                                              "multipleArtists": multipleArtists,
                                                              "authorId": media.id})
            }
        }

        PullDownMenu {
            id: artistAlbumsMenu

            MenuItem {
                //: List all songs of this artist
                //% "List all songs"
                text: qsTrId("mediaplayer-me-show-all-artist-songs")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("ArtistAllSongsPage.qml"), {media: media})
            }

            NowPlayingMenuItem { }

            MenuItem {
                id: menuItemSearch

                //: Search menu entry
                //% "Search"
                text: qsTrId("mediaplayer-me-search")
                onClicked: albumsHeader.enableSearch()
                enabled: view.count > 0 || albumsHeader.searchText !== ''
            }
        }

        ViewPlaceholder {
            text: {
                if (albumsHeader.searchText !== '') {
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
            id: albumsHeader
            width: parent.width

            // TODO: Shouldn't we place here the artist name, instead?

            //: title for the Artist page
            //% "Albums"
            title: qsTrId("mediaplayer-he-albums")

            //: Albums search field placeholder text
            //% "Search album"
            placeholderText: qsTrId("mediaplayer-tf-albums-search")
        }

        delegate: MediaContainerListDelegate {
            id: delegate

            contentHeight: albumArt.height
            leftPadding: albumArt.width + Theme.paddingLarge
            formatFilter: albumsHeader.searchText
            title: media.title
            subtitle: media.author
            titleFont.pixelSize: Theme.fontSizeLarge
            subtitleFont.pixelSize: Theme.fontSizeMedium
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("AlbumPage.qml"), {media: media})

            ListView.onAdd: AddAnimation { target: delegate }
            ListView.onRemove: animateRemoval()

            AlbumArt {
                id: albumArt

                source: albumArtProvider.albumThumbnail(title, subtitle)
                highlighted: delegate.highlighted
            }
        }
    }
}
