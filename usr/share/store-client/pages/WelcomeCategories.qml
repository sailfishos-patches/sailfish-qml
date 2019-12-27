import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0


Item {
    property alias model: categoriesRepeater.model

    width: parent.width
    height: categoriesColumn.height

    WelcomeBoxBackground {
        visible: categoriesColumn.height > 0
        width: parent.width
        height: Theme.itemSizeSmall
    }

    Column {
        id: categoriesColumn
        width: parent.width
        Repeater {
            id: categoriesRepeater
            delegate: MoreButton {
                width: parent.width
                height: Theme.itemSizeMedium
                text: jollaStore.categoryName(modelData)
                visible: modelData !== "" && modelData !== "0"
                onClicked: {
                    navigationState.openCategory(modelData, ContentModel.TopNew)
                }
            }
        }
    }
}
