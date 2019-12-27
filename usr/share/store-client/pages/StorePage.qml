import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

Page {
    id: page
    objectName: "StorePage"

    property string title
    property alias scope: storeModel.scope
    property alias filter: storeModel.filter
    property alias startsWith: storeModel.startsWith
    property alias category: storeModel.category
    property alias topListType: storeModel.topListType
    property alias sortMode: storeModel.sortMode
    readonly property bool loading: storeModel.loading

    property bool _condition: status === PageStatus.Active &&
                              jollaStore.connectionState === JollaStore.Ready

    function pageTitle() {
        if (title === "") {
            if (topListType === ContentModel.TopLiked) {
                //: Page header for the Top of all apps page
                //% "Top apps"
                return qsTrId("jolla-store-he-top_apps_all")
            } else if (topListType === ContentModel.TopNew) {
                //: Page header for the New of all apps page
                //% "New apps"
                return qsTrId("jolla-store-he-new_apps_all")
            } // "non-filtered" TopDownloaded not in use at the moment.
        }
        return title
    }

    function subTitle() {
        if (title === "") {
            return ""
        } else if (topListType === ContentModel.TopLiked) {
            //: Page sub header when apps are sorted by number of likes
            //% "Most liked"
            return qsTrId("jolla-store-la-most_liked_apps")
        } else if (topListType === ContentModel.TopNew) {
            //: Page sub header when apps are sorted by date
            //% "Latest"
            return qsTrId("jolla-store-la-latest_apps")
        } else if (topListType === ContentModel.TopDownloaded) {
            //: Page sub header when apps are sorted by number of downloads
            //% "Most downloaded"
            return qsTrId("jolla-store-la-most_downloaded_apps")
        } else {
            return ""
        }
    }

    on_ConditionChanged: {
        if (_condition) {
            // refresh the model once the store server becomes available
            storeModel.refresh()

            // destroy the binding to not trigger anymore
            _condition = false

            if (category !== "" && jollaStore.categories(category).length > 0) {
                pageStack.pushAttached(Qt.resolvedUrl("CategoriesPage.qml"), {"category": category})
            }
        }
    }

    ContentModel {
        id: storeModel
        objectName: "storeModel"

        store: jollaStore
        packager: packageHandler
        topListType: ContentModel.TopNew

        onHasMoreChanged: gridView.fetchMoreIfNeeded()
    }

    SilicaGridView {
        id: gridView
        anchors.fill: parent
        model: storeModel
        cellHeight: gridItemForSize.height + appGridSpacing
        cellWidth: Math.floor(page.width / appGridColumns)
        cacheBuffer: page.height

        function fetchMoreIfNeeded() {
            if (!storeModel.loading
                    && storeModel.hasMore
                    && indexAt(contentX, contentY + height) > storeModel.count - 54 /* ~ three pages ahead */) {
                storeModel.fetchMoreContent()
            }
        }

        onContentYChanged: fetchMoreIfNeeded()

        header: Column {
            width: gridView.width
            PageHeader {
                title: pageTitle()
            }

            SectionHeader {
                visible: text !== ""
                text: subTitle()
                height: implicitHeight + Theme.paddingLarge
                verticalAlignment: Text.AlignTop
            }
        }

        footer: Item {
            visible: jollaStore.isOnline
                     && storeModel.loading
                     && !pageBusyIndicator.running
            height: visible ? Theme.itemSizeSmall : 0
            width: gridView.width

            BusyIndicator {
                anchors.centerIn: parent
                running: parent.visible
                size: BusyIndicatorSize.Medium
            }
        }

        delegate: Item {
            id: delegate
            width: gridView.cellWidth
            height: gridView.cellHeight

            AppGridItem {
                // Compensate the offset caused by margins + spacings
                x: appGridMargin - (index % appGridColumns) * (parent.width - width - appGridSpacing)
                width: gridItemForSize.width
                height: gridItemForSize.height

                title: model ? model.title : ""
                author: model ? (model.companyUuid !== "" ? model.companyName : model.userName) : ""
                appCover: model ? model.cover : ""
                appIcon: model ? model.icon : ""
                likes: model ? model.likes : 0
                appState: model ? model.appState : ApplicationState.Normal
                progress: model ? model.progress : 100
                androidApp: model ? model.androidApp : false

                onClicked: {
                    navigationState.openApp(model.uuid, model.appState)
                }
            }
            GridView.onAdd: AddAnimation { duration: 500; target: delegate }
        }

        PullDownMenu {
            MenuItem {
                visible: page.title !== ""
                //: Sort menu item
                //% "Sort"
                text: qsTrId("jolla-store-me-sort")

                onClicked: {
                    var obj = pageStack.animatorPush(Qt.resolvedUrl("SortPage.qml"))
                    obj.pageCompleted.connect(function(sortPage) {
                        sortPage.selected.connect(function(sortType) {
                            if (storeModel.topListType !== sortType) {
                                storeModel.topListType = sortType
                                storeModel.refresh()
                            }
                            pageStack.pop()
                        })
                    })
                }
            }

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

        BusyIndicator {
            id: pageBusyIndicator
            anchors.centerIn: parent
            running: jollaStore.isOnline
                     && storeModel.loading
                     && !pageStack.busy
                     && storeModel.count === 0
            size: BusyIndicatorSize.Large
        }

        OfflinePlaceholder {
            condition: gridView.count === 0
        }

        ViewPlaceholder {
            id: placeHolder
            enabled: jollaStore.isOnline &&
                     !storeModel.loading &&
                     !pageStack.busy &&
                     storeModel.count === 0
            //: View placeholder when there's no content to display
            //% "No content"
            text: qsTrId("jolla-store-li-no_content")
        }

        VerticalScrollDecorator {}
    }

    OfflineButton {
        condition: gridView.count === 0
    }

    AttachedPageHint {}
}
