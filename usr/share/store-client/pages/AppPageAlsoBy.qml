import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

Item {
    id: appPageAlsoBy

    property ApplicationData app
    property int horizontalMargin: Theme.horizontalPageMargin
    property int gridMargin: Theme.horizontalPageMargin

    property int _gridColumns: 2

    width: parent.width
    height: authorColumn.height
    visible: app.inStore && !authorContentModel.loading && authorContentModel.count > 0

    // model for loading other apps by the author
    ContentModel {
        id: authorContentModel
        objectName: "authorContentModel"

        store: jollaStore
        packager: packageHandler
        scope: app.company !== "" ? "company" : "user"
        filter: app.company !== "" ? app.company : app.user
        // We only show max "_gridColumns" items but need to fetch "_gridColumns + 2"
        // so that we know whether to show the "more" button or not. One of the
        // fetched items might be this app and the exclusion is handled on client
        // side, so "_gridColumns + 1" is not enough.
        limit: _gridColumns + 2
        excludes: [app.application]

        Component.onCompleted: {
            authorContentModel.refresh()
        }
    }

    Column {
        id: authorColumn
        width: parent.width

        MoreButton {
            width: parent.width
            height: Theme.itemSizeMedium
            horizontalMargin: appPageAlsoBy.horizontalMargin
            enabled: authorContentModel.count > _gridColumns
            //: From same developer action button label. Takes the author name as a parameter.
            //% "Also from %1"
            text: qsTrId("jolla-store-li-also_from").arg(app.authorName)

            onClicked: {
                navigationState.openAuthor(app.authorName,
                                           authorContentModel.scope,
                                           authorContentModel.filter)
            }
        }

        Grid {
            id: authorAppGrid
            x: gridMargin
            width: parent.width - 2 * x
            columns: _gridColumns
            spacing: appGridSpacing

            Repeater {
                model: authorContentModel
                AppGridItem {
                    width: Math.floor((authorColumn.width - 2 * gridMargin - (_gridColumns - 1) * appGridSpacing) / _gridColumns)
                    visible: model.index < _gridColumns
                    title: model.title
                    author: model.companyUuid !== "" ? model.companyName : model.userName
                    appCover: model.cover
                    appIcon: model.icon
                    likes: model.likes
                    appState: model.appState
                    progress: model.progress
                    androidApp: model.androidApp

                    onClicked: {
                        navigationState.openApp(model.uuid, model.appState)
                    }
                }
            }
        }
    }
}

