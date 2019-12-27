import QtQuick 2.6
import Sailfish.Silica 1.0

Page {
    id: root

    property alias propertyModel: listView.model

    signal propertySelected(var propertyData)

    function openContextMenu(menu, menuProperties) {
        if (!listView.currentItem) {
            console.warn("Cannot open context menu, property picker does not have a currentItem!")
            return
        }
        listView.currentItem.menu = menu
        listView.currentItem.openMenu(menuProperties)
    }

    SilicaListView {
        id: listView

        anchors.fill: parent

        header: PageHeader {
            //: Choose an option from the list
            //% "Select"
            title: qsTrId("components_contacts-he-select")
        }

        delegate: ListItem {
            id: delegateItem

            onClicked: {
                listView.currentIndex = model.index
                root.propertySelected(root.propertyModel.get(model.index))
            }

            Label {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - x*2
                wrapMode: Text.Wrap
                text: model.displayLabel
                highlighted: delegateItem.highlighted
            }
        }

        VerticalScrollDecorator {}
    }
}
