// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.mediaplayer 1.0

Page {
    id: artistsPage
    property var model
    property string searchText

    function formatDuration(duration) {
        var secs = parseInt(duration)
        var mins = Math.floor(secs / 60)
        var hours = Math.floor(mins / 60)
        var minutes = mins - (hours * 60)

        //: duration in hours of the songs belonging to an artist
        //% "%n hours"
        var hourString = qsTrId("mediaplayer-la-artist-songs-duration-hours", hours)

        //: duration in minutes of the songs belonging to an artist
        //% "%n minutes"
        var minuteString = qsTrId("mediaplayer-la-artist-songs-duration-minutes", minutes)

        //: the duration shown below the artist name in the artists page,
        //: %1 is hour string ("N hours"), %2 is minute string
        //% "%1, %2"
        return hours > 0
                ? qsTrId("mediaplayer-la-artist-songs-duration-hours-minutes").arg(hourString).arg(minuteString)
                : minuteString
    }

    TrackerQueriesBuilder {
        id: queriesBuilder
    }

    MediaPlayerListView {
        id: view

        model: artistsPage.model
        property string query: queriesBuilder.getArtistsQuery(artistsHeader.searchText)

        Binding {
            target: artistsPage.model.source
            property: "query"
            value: view.query
        }

        delegate: MediaContainerListDelegate {
            id: delegate

            formatFilter: artistsHeader.searchText
            title: media.title
            subtitle: artistsPage.formatDuration(media.childCount)
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("ArtistPage.qml"), {media: media})

            ListView.onAdd: AddAnimation { target: delegate }
            ListView.onRemove: animateRemoval()
        }


        PullDownMenu {
            id: artistsMenu

            NowPlayingMenuItem { }

            MenuItem {
                id: menuItemSearch

                //: Search menu entry
                //% "Search"
                text: qsTrId("mediaplayer-me-search")
                onClicked: artistsHeader.enableSearch()
                enabled: view.count > 0 || artistsHeader.searchText !== ''
            }
        }

        ViewPlaceholder {
            text: {
                if (artistsHeader.searchText !== '') {
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
            id: artistsHeader
            width: parent.width

            //: Title for the Artists page
            //% "Artists"
            title: qsTrId("mediaplayer-he-artists")

            //: Artists search field placeholder text
            //% "Search artist"
            placeholderText: qsTrId("mediaplayer-tf-artists-search")

            searchText: artistsPage.searchText
            Component.onCompleted: if (searchText !== '') enableSearch()
        }
    }
}
