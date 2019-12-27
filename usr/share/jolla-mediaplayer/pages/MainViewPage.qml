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
            id: mainPageMenu

            NowPlayingMenuItem { }

            MenuItem {
                id: menuItemSearch

                //: Search menu entry
                //% "Search"
                text: qsTrId("mediaplayer-me-search")
                onClicked: mainPageHeader.enableSearch()
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

            Item {
                id: playlistsItem

                width: parent.width
                height: {
                    var height = playlistsCategory.shouldBeVisible ? playlistsCategory.height : 0
                    if (playlists.populated && playlistRow.count === 0) {
                        // It really shouldn't be possible to do this, but opening a content
                        // menu already animates the overall height and we don't want a second
                        // animation making that lag, so we disable the behavior when a menu
                        // is opened. If something else causes the height to animate we want to
                        // restore that before the value is written.
                        playlistHeightBehavior.enabled = true
                    } else if (remorseContainer.__silica_remorse_item) {
                        playlistHeightBehavior.enabled = true
                        height += Theme.itemSizeExtraLarge + Theme.itemSizeSmall
                    } else {
                        height += playlistRow.height
                    }
                    return height
                }

                clip: playlistRow.count > playlistRow.maxCount || playlistHeightAnimation.running

                Behavior on height {
                    id: playlistHeightBehavior
                    NumberAnimation {
                        id: playlistHeightAnimation

                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }

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
                    subtitle: populated && !createNew ? qsTrId("mediaplayer-la-number-of-playlists", playlists.count)
                                                 : " "
                    onClicked: {
                        if (createNew) {
                            pageStack.animatorPush("com.jolla.mediaplayer.NewPlaylistDialog")
                        } else {
                            pageStack.animatorPush(Qt.resolvedUrl("PlaylistsPage.qml"), {searchText: mainPageHeader.searchText})
                        }
                    }
                }

                ListView {
                    id: playlistRow

                    readonly property int maxCount: Math.floor(parent.width / Theme.itemSizeExtraLarge)

                    anchors.top: playlistsCategory.bottom
                    width: parent.width
                    height: Theme.itemSizeExtraLarge

                    opacity: count > 0 ? 1.0 : 0.0
                    Behavior on opacity { FadeAnimator {} }
                    visible: !playlists.populated || count > 0 || playlistHeightAnimation.running

                    orientation: ListView.Horizontal
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
                        id: playlistItem

                        property Item remorse

                        width: playlistRow.width / Math.max(playlistRow.maxCount, 1)
                        menu: menuComponent
                        highlighted: down || menuOpen
                        color: model.title != "" ? PlaylistColors.nameToColor(model.title)
                                                 : "transparent"
                        highlightColor: model.title != "" ? PlaylistColors.nameToHighlightColor(model.title)
                                                          : "transparent"
                        enabled: !remorse

                        onMenuOpenChanged: {
                            if (menuOpen)
                                playlistHeightBehavior.enabled = false
                        }

                        function remove() {
                            if (remorseContainer.__silica_remorse_item) {
                                remorseContainer.__silica_remorse_item.trigger()
                            }

                            remorse = remorseComponent.createObject(playlistItem)
                            //: Deleting in n seconds
                            //% "Deleting"
                            remorse.execute(remorseContent,
                                            qsTrId("mediaplayer-la-deleting"),
                                            function() {
                                                playlists.removePlaylist(media)
                                            })
                        }

                        Component {
                            id: menuComponent
                            ContextMenu {
                                id: menu
                                width: playlistRow.width
                                x: {
                                    if (!parent) return 0

                                    var offset = 0
                                    var p = parent
                                    do {
                                        offset += p.x
                                        p = p.parent
                                    } while (p !== playlistRow)

                                    return -offset
                                }

                                MenuItem {
                                    //: Remove playlist context menu entry in playlists page
                                    //% "Remove playlist"
                                    text: qsTrId("mediaplayer-me-playlists-remove-playlist")
                                    onClicked: remove()
                                }
                            }
                        }
                    }
                }
                Item {
                    id: remorseContainer

                    property Item __silica_remorse_item

                    y: playlistRow.y + playlistRow.height
                    width: playlistRow.width
                    height: playlistsItem.height - y
                    z: 1
                    clip: true

                    Item {
                        id: remorseContent
                        width: playlistRow.width
                        height: Theme.itemSizeSmall
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

    Component {
        id: remorseComponent
        RemorseItem {
            horizontalAlignment: Text.AlignHCenter

            //: RemorseItem cancel help text
            //% "Cancel"
            cancelText: qsTrId("mediaplayer-la-cancel-deletion")

            onCanceled: destroy()
        }
    }
}
