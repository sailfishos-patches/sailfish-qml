import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

Column {
    property alias model: appRepeater.model
    property alias busy: moreButton.busy
    property alias title: moreButton.text

    width: parent.width

    MoreButton {
        id: moreButton
        width: parent.width
        height: Theme.itemSizeMedium
        enabled: jollaStore.connectionState === JollaStore.Ready

        onClicked: {
            navigationState.openCategory("", model.topListType)
        }

        WelcomeBoxBackground {
            anchors.fill: parent
            z: -1
        }
    }

    Grid {
        x: appGridMargin
        width: parent.width - 2 * appGridMargin
        columns: appGridColumns
        spacing: appGridSpacing
        Repeater {
            id: appRepeater
            AppGridItem {
                width: gridItemForSize.width
                height: gridItemForSize.height
                visible: model.index < 3 * appGridColumns

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

    Item { width: 1; height: Theme.paddingMedium; visible: !busy }
}
