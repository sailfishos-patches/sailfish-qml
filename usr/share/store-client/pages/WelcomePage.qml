import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

/* Welcome Page
 *
 * The purpose of the welcome page is to present the user with a selection of
 * recommended apps, as well as with the list of categories.
 */
Page {
    id: page
    objectName: "WelcomePage"

    property int feedColumns: {
        if (Screen.sizeCategory > Screen.Medium) {
            return _isPortrait ? 3 : 4
        } else {
            return _isPortrait ? 2 : 3
        }
    }
    property int recommendedColumns: {
        if (Screen.sizeCategory > Screen.Medium) {
            return _isPortrait ? 2 : 3
        } else {
            return _isPortrait ? 1 : 2
        }
    }

    property bool initialized
    property bool _condition: status === PageStatus.Active &&
                              jollaStore.connectionState === JollaStore.Ready

    onRecommendedColumnsChanged: {
        if (initialized && recommendedModel.count < recommendedColumns) {
            recommendedModel.fetchContent(recommendedColumns - recommendedModel.count)
        }
    }

    on_ConditionChanged: {
        if (_condition) {
            // refresh the models once the store server becomes available
            recommendedModel.reset()
            recommendedModel.insertPromo()
            if (recommendedColumns > 1) {
                recommendedModel.fetchContent(recommendedColumns - 1)
            }
            feedModel.reset()
            feedModel.fetchContent(Screen.sizeCategory > Screen.Medium ? 20 : 10)
            newModel.refresh()
            likedModel.refresh()
            welcomeCategories.model = jollaStore.categories("")

            // destroy the binding to not trigger anymore
            _condition = false
            initialized = true
        }
    }

    FeedTimer {
        model: recommendedModel
        pageStatus: page.status
        pullDownMenu: pullDownMenu
        interval: 10000
    }

    FeedTimer {
        model: feedModel
        pageStatus: page.status
        pullDownMenu: pullDownMenu
        interval: 6000
    }

    FeedModel {
        id: recommendedModel
        objectName: "recommendedModel"
        store: jollaStore
        packager: packageHandler
        feedType: Feed.Recommendation
    }

    FeedHeadModel {
        id: recommendedHeadModel
        sourceModel: recommendedModel
        length: recommendedColumns
    }

    FeedModel {
        id: feedModel
        objectName: "feedModel"
        store: jollaStore
        packager: packageHandler
        columns: feedColumns
    }

    ContentModel {
        id: newModel
        objectName: "newModel"
        store: jollaStore
        packager: packageHandler
        sortMode: ContentModel.SortByAge
        scope: "store"
        topListType: ContentModel.TopNew
        limit: 3 * maxAppGridColumns
    }

    ContentModel {
        id: likedModel
        objectName: "likedModel"
        store: jollaStore
        packager: packageHandler
        sortMode: ContentModel.SortByTop
        scope: "store"
        topListType: ContentModel.TopLiked
        limit: 3 * maxAppGridColumns
    }

    ContentStatus { id: recommendedStatus; model: recommendedModel; limit: recommendedColumns }
    ContentStatus { id: feedStatus; model: feedModel }
    ContentStatus { id: newStatus; model: newModel }
    ContentStatus { id: likedStatus; model: likedModel }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width

            WelcomeRecommendedItem {
                model: recommendedHeadModel
                columns: recommendedColumns
                busy: !recommendedStatus.populated
            }

            WelcomeFeedItem {
                model: feedModel
                busy: !feedStatus.populated
            }

            WelcomeAppGrid {
                model: newModel
                busy: !newStatus.populated
                //: A text for a button that opens the new apps page
                //% "New apps"
                title: qsTrId("jolla-store-li-new_apps_button")
            }

            WelcomeAppGrid {
                model: likedModel
                busy: !likedStatus.populated
                //: A text for a button that opens the top apps page
                //% "Top apps"
                title: qsTrId("jolla-store-li-top_apps_button")
            }

            WelcomeCategories {
                id: welcomeCategories
                visible: recommendedStatus.populated ||
                         feedStatus.populated ||
                         newStatus.populated ||
                         likedStatus.populated
            }
        }

        PullDownMenu {
            id: pullDownMenu
            visible: jollaStore.connectionState === JollaStore.Ready

            MenuItem {
                //: My apps menu item
                //% "My apps"
                text: qsTrId("jolla-store-me-my_apps")

                onClicked: {
                    navigationState.openInstalled(false)
                }
            }

            MenuItem {
                //: Search menu item
                //% "Search"
                text: qsTrId("jolla-store-me-search")

                onClicked: {
                    navigationState.openSearch(false)
                }
            }
        }

        OfflinePlaceholder {
            visible: content.height === 0 &&
                     (jollaStore.connectionState === JollaStore.ServerError ||
                      !jollaStore.isOnline)
        }

        VerticalScrollDecorator { }
    }

    OfflineButton {
        condition: content.height === 0
    }
}
