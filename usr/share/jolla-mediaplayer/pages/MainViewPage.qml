// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
import com.jolla.mediaplayer 1.0

Page {
    id: mainPage

    signal mediaSourceActivated(Item source)

    FilterModel {
        id: filteredMediaSourceList

        sourceModel: mediaSourceList

        // Filter out if the value is not "1"
        filterRegExp: mainPageHeader.searchText !== "" ? /^1$/ : RegExp("")
    }

    MediaPlayerListView {
        id: mainListView
        model: filteredMediaSourceList
        anchors.fill: parent

        PullDownMenu {
            // FIXME: hiding search on this page now due to performing badly, should be reimplemented better
            visible: visualAudioAppModel.active
            NowPlayingMenuItem { id: nowPlaying }

            MenuItem {
                //: Search menu entry
                //% "Search"
                text: qsTrId("mediaplayer-me-search")
                onClicked: mainPageHeader.enableSearch()
                visible: false
            }
        }

        header: SearchPageHeader {
            id: mainPageHeader
            width: parent.width
            searchAsHeader: true

            //: Title for the main page
            //% "Media"
            title: qsTrId("mediaplayer-he-media")

            //: Main view search field placeholder text
            //% "Search Media"
            placeholderText: qsTrId("mediaplayer-tf-search-media")

            Binding {
                target: mediaSourceList
                property: "searchText"
                value: if (pageStack.currentPage === mainPage) mainPageHeader.searchText
            }

            Column {
                id: playlistsItem

                width: parent.width
                height: {
                    var height = playlistsCategory.shouldBeVisible ? playlistsCategory.height : 0
                    if (playlists.populated && playlistRow.count === 0) {
                        return height
                    } else {
                        return height + playlistRow.height
                    }
                }

                clip: playlistRow.count > playlistRow.maxCount
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                MediaContainerIconDelegate {
                    id: playlistsCategory

                    readonly property bool populated: playlists.populated
                    readonly property bool createNew: playlists.count == 0
                    readonly property bool shouldBeVisible: playlists.count !== 0 || mainPageHeader.searchText === ""

                    width: parent.width
                    opacity: shouldBeVisible ? 1.0 : 0.0
                    Behavior on opacity { FadeAnimation {} }
                    visible: opacity > 0.0
                    iconSource: "image://theme/icon-m-media-playlists"
                    title: !populated ? " "
                                      : createNew
                                        ? //: Playlists list item in the main view
                                          //% "New playlist"
                                          qsTrId("mediaplayer-me-new-playlist")
                                        : //: Playlists list item in the main view
                                          //% "Playlists"
                                          qsTrId("mediaplayer-la-playlists")

                    //: Number of playlists
                    //% "%n playlists"
                    subtitle: populated ? (!createNew ? qsTrId("mediaplayer-la-number-of-playlists", playlists.count) : "")
                                        : " "
                    onClicked: {
                        if (createNew) {
                            pageStack.animatorPush("com.jolla.mediaplayer.NewPlaylistDialog")
                        } else {
                            pageStack.animatorPush(Qt.resolvedUrl("PlaylistsPage.qml"), {searchText: mainPageHeader.searchText})
                        }
                    }
                }

                SilicaGridView {
                    id: playlistRow

                    readonly property int maxCount: Math.floor(parent.width / Theme.itemSizeExtraLarge)

                    width: parent.width
                    height: Theme.itemSizeExtraLarge + __silica_menu_height
                    cellHeight: Theme.itemSizeExtraLarge
                    cellWidth: width / Math.max(maxCount, 1)
                    flow: GridView.FlowTopToBottom

                    opacity: count > 0 ? 1.0 : 0.0
                    Behavior on opacity { FadeAnimator {} }
                    visible: !playlists.populated || count > 0

                    interactive: false
                    model: GriloTrackerModel {
                        id: playlistModel
                        query: PlaylistTrackerHelpers.getPlaylistsQuery(mainPageHeader.searchText, {"sortByUsage": true})
                    }

                    Connections {
                        target: playlists
                        onUpdated: playlistModel.refresh()
                    }

                    delegate: PlaylistItem {
                        width: playlistRow.cellWidth
                        contentHeight: playlistRow.cellHeight

                        highlighted: down || menuOpen
                        color: model.title != "" ? PlaylistColors.nameToColor(model.title)
                                                 : "transparent"
                        highlightColor: model.title != "" ? PlaylistColors.nameToHighlightColor(model.title)
                                                          : "transparent"

                        menu: Component {
                            ContextMenu {
                                MenuItem {
                                    //% "Delete"
                                    text: qsTrId("mediaplayer-me-delete")
                                    onClicked: remove()
                                }
                            }
                        }

                        function remove() {
                            remorseDelete(function() {
                                playlists.removePlaylist(media)
                            })
                        }
                    }
                }
            }
        }

        delegate: MediaContainerIconDelegate {
            id: delegate

            width: ListView.view.width
            title: mediaSource.title
            subtitle: mediaSource.subtitle
            iconSource: mediaSource.icon
            iconSourceSize.width: Theme.iconSizeMedium
            iconSourceSize.height: Theme.iconSizeMedium

            onClicked: {
                var obj = pageStack.animatorPush(Qt.resolvedUrl(mediaSource.mainView),
                                          {model: mediaSource.model, searchText: mediaSource.searchText})
                obj.pageCompleted.connect(function(view) {
                    mainPage.mediaSourceActivated(view)
                })
            }
            ListView.onAdd: AddAnimation { target: delegate }
            ListView.onRemove: animateRemoval()
        }

        ViewPlaceholder {
            //: Placeholder text for an empty search view
            //% "No items found"
            text: qsTrId("mediaplayer-la-empty-search")
            enabled: mainListView.count === 0 && !playlistRow.visible && !playlistsCategory.visible
        }
    }
}
