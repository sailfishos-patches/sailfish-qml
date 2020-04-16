import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

Page {
    id: page
    objectName: "SearchPage"

    property bool _showOtherStores: searchModel.count === 0
                                    && searchModel.filter !== ""
                                    && !searchModel.loading
                                    && !offlinePlaceholder.enabled

    onStatusChanged: {
        if (status === PageStatus.Active && searchModel.count === 0) {
            searchEntry.cursorPosition = searchEntry.text.length
            searchEntry.forceActiveFocus()
        }
    }

    on_ShowOtherStoresChanged: {
        if (_showOtherStores && otherStoresModel.count === 0) {
            otherStoresModel.category = jollaStore.marketPlacesCategory()
            otherStoresModel.refresh()
        }
    }

    ContentModel {
        id: searchModel
        objectName: "searchModel"

        store: jollaStore
        packager: packageHandler
        sortMode: ContentModel.SortNone

        scope: "search"
        filter: ""

        onHasMoreChanged: gridView.fetchMoreIfNeeded()
    }

    SearchAssistant {
        id: searchAssistant
        store: jollaStore
        searchTerm: searchEntry.text
        limit: 3
    }

    ContentModel {
        id: otherStoresModel

        store: jollaStore
        packager: packageHandler
        sortMode: ContentModel.SortByName
        scope: "store"
    }

    SilicaGridView {
        id: gridView

        anchors.fill: parent
        model: searchEntry.activeFocus ? null
                                       : _showOtherStores ? otherStoresModel
                                                          : searchModel

        cellHeight: gridItemForSize.height + appGridSpacing
        cellWidth: Math.floor(page.width / appGridColumns)
        cacheBuffer: page.height

        function fetchMoreIfNeeded() {
            if (!searchModel.loading
                    && searchModel.hasMore
                    && indexAt(contentX, contentY + height) > searchModel.count - 54 /* ~ three pages */) {
                searchModel.fetchMoreContent()
            }
        }

        onContentYChanged: fetchMoreIfNeeded()

        header: Item {
            // This is just a placeholder for the header box. To avoid the
            // list view resetting the input box everytime the model resets,
            // the search entry is defined outside the list view.
            width: gridView.width
            height: headerBox.height
        }

        footer: Item {
            visible: jollaStore.isOnline
                     && searchModel.loading
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
                    if (_showOtherStores && model.appState === ApplicationState.Installed) {
                        launcher.packageName = model.packageName
                        if (launcher.isExecutable) {
                            launcher.launchApplication()
                            return
                        }
                    }
                    navigationState.openApp(model.uuid, model.appState)
                }
            }
            GridView.onAdd: AddAnimation { duration: 200; target: delegate }
            GridView.onRemove: RemoveAnimation { duration: 200; target: delegate }
        }

        PullDownMenu {
            MenuItem {
                //: My apps menu item
                //% "My apps"
                text: qsTrId("jolla-store-me-my_apps")

                onClicked: {
                    navigationState.openInstalled(false)
                }
            }
        }

        PageBusyIndicator {
            id: pageBusyIndicator
            running: jollaStore.isOnline
                     && searchModel.filter !== ""
                     && searchModel.loading
                     && searchModel.count === 0
        }

        OfflinePlaceholder {
            id: offlinePlaceholder
            // do not show the offline place holder while having valid content
            // that can still be clicked by the user, even while offline
            condition: searchModel.count === 0
        }

        VerticalScrollDecorator {}
    }

    Column {
        id: headerBox

        parent: gridView.headerItem ? gridView.headerItem : page
        width: parent.width

        PageHeader {
            id: pageHeader
            //: Page header for the search page
            //% "Jolla Store"
            title: qsTrId("jolla-store-he-search")
        }

        SearchField {
            id: searchEntry

            function search(searchTerm) {
                focus = false
                if (text !== searchTerm) {
                    text = searchTerm
                }

                if (jollaStore.isOnline) {
                    searchModel.filter = searchTerm
                    searchModel.refresh()
                } else {
                    // the user cannot search while offline. content (if any)
                    // will disappear and the offline placeholder will show
                    searchModel.reset()
                }
            }

            width: parent.width
            //: Placeholder text for the Search field
            //% "Search"
            placeholderText: qsTrId("jolla-store-ph-search")
            text: searchModel.filter

            onTextChanged: {
                if (text === "") {
                    searchModel.filter = ""
                    searchModel.reset()
                }
            }

            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.enabled: text != ""
            EnterKey.onClicked: {
                if (text !== "") {
                    focus = false
                    search(text)
                }
            }
        }

        Repeater {
            model: searchEntry.activeFocus ? searchAssistant : null

            ListItem {
                width: headerBox.width
                opacity: 0

                Behavior on opacity {
                    FadeAnimator { duration: 200 }
                }

                Label {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: searchEntry.textLeftMargin
                        rightMargin: Theme.horizontalPageMargin
                    }

                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeLarge
                    textFormat: Text.StyledText
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                    text: Theme.highlightText(model.suggestion, searchEntry.text, Theme.highlightColor)
                }

                onClicked: {
                    searchEntry.search(model.suggestion)
                }

                Component.onCompleted: {
                    opacity = 1
                }

            }
        }

        Item {
            width: parent.width
            visible: _showOtherStores && otherStoresModel.count && !searchEntry.activeFocus
            opacity: visible ? 1.0 : 0.0

            onVisibleChanged: {
                if (visible) {
                    // Calculate the height so that the "other app stores" appear
                    // at the bottom of the screen.
                    height = Qt.binding(function() {
                        var gridHeight = Math.ceil(otherStoresModel.count / appGridColumns) * gridView.cellHeight
                        return page.height - gridHeight - pageHeader.height - searchEntry.height
                    })
                } else {
                    height = 0
                }
            }

            Behavior on opacity { FadeAnimator { duration: 500 } }

            InfoLabel {
                width: parent.width - 2 * Theme.paddingLarge
                anchors.centerIn: parent
                //: Label shown when the search turned up nothing to invite the
                //: user to also try 3rd party Android app stores.
                //% "Sorry, we couldn't find anything. Check also Android market places."
                text: qsTrId("jolla-store-li-try_other_stores")
            }
        }
    }

    AppLauncher { id: launcher }
}
