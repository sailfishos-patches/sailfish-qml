import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

/* Feed Page
 */
Page {
    id: page
    objectName: "FeedPage"

    property var model
    // The height of the smallest feed item is a bit more than 2 * iconSizeLauncher
    property int _maxVisibleItems: Math.ceil(height / (2 * Theme.iconSizeLauncher))

    FeedTimer {
        model: page.model
        pageStatus: page.status
        pullDownMenu: pullDownMenu
        interval: 6000
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content

            PageHeader {
                //: Page header for the Store feed (activity) page
                //% "Activity"
                title: qsTrId("jolla-store-he-feed_page")
            }

            Row {
                width: page.width
                Repeater {
                    id: feedRowsRepeater
                    model: page.model.columnModels
                    Column {
                        width: Math.floor(page.width / feedRowsRepeater.count)

                        move: Transition {
                            NumberAnimation {
                                properties: "y"
                                duration: 200
                                easing.type: Easing.InOutQuad
                            }
                        }

                        Repeater {
                            model: modelData

                            Loader {
                                width: parent ? parent.width : 0
                                // Load the invisible items asynchronously
                                asynchronous: index >= _maxVisibleItems
                                visible: status === Loader.Ready
                                sourceComponent: Component {
                                    AppFeedItem {
                                        uuid: model.uuid
                                        title: model.title
                                        text: model.text
                                        appTitle: model.appTitle
                                        appIcon: model.icon
                                        appState: model.appState
                                        progress: model.progress
                                        itemType: model.type
                                        androidApp: model.androidApp
                                        opacity: visible ? 1.0 : 0.0

                                        // Cannot use Grid's "add" transition for this because of the Loader.
                                        Behavior on opacity { FadeAnimation { duration: 500 } }

                                        onClicked: {
                                            if (model.collection !== "") {
                                                navigationState.openCategory(collection, ContentModel.TopNew)
                                            } else {
                                                navigationState.openApp(model.uuid, model.appState)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
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

        // indicator that is shown while loading initial content from the store
        BusyIndicator {
            // Keep ViewPlaceholder and BusyIndicator positions in sync
            anchors.centerIn: offlinePlaceholder
            // Need to reparent because ViewPlaceholder reparents itself
            parent: offlinePlaceholder.parent
            running: jollaStore.isOnline &&
                     (jollaStore.connectionState === JollaStore.Connecting
                      || (jollaStore.connectionState === JollaStore.Ready
                          && model.loading
                          && model.count === 0))
            size: BusyIndicatorSize.Large
        }

        OfflinePlaceholder {
            id: offlinePlaceholder
            condition: model.count === 0
        }

        VerticalScrollDecorator { }
    }

    OfflineButton {
        condition: model.count === 0
    }
}
