// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.mediaplayer 1.0
import org.nemomobile.thumbnailer 1.0

Page {
    id: albumsPage

    property var model
    property string searchText

    TrackerQueriesBuilder {
        id: queriesBuilder
    }

    MediaPlayerListView {
        id: view

        property string query: queriesBuilder.getAlbumsQuery(albumsHeader.searchText)

        model: albumsPage.model

        Binding {
            target: albumsPage.model.source
            property: "query"
            value: view.query
        }

        PullDownMenu {

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

            //: title for the Albums page
            //% "Albums"
            title: qsTrId("mediaplayer-he-albums")

            //: Albums search field placeholder text
            //% "Search album"
            placeholderText: qsTrId("mediaplayer-tf-albums-search")

            searchText: albumsPage.searchText
            Component.onCompleted: if (searchText !== '') enableSearch()
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
