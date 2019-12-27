import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    property var menu
    property alias propertyModel: repeater.model

    signal propertySelected(var propertyData)

    Repeater {
        id: repeater
        parent: menu._contentColumn // context menu touch requires menu items are children of content area

        MenuItem {
            text: model.displayLabel
            truncationMode: TruncationMode.Fade

            onClicked: root.propertySelected(propertyModel.get(model.index))
        }
    }
}
