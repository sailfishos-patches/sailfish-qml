import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

Page {
    property string category

    onStatusChanged: {
        if (status === PageStatus.Active && !listview.model) {
            listview.model = jollaStore.categories(category)
        }
    }

    SilicaListView {
        id: listview

        anchors.fill: parent

        header: PageHeader {
            title: category === ""
                   //: Page header for the categories page
                   //% "Categories"
                   ? qsTrId("jolla-store-he-categories")
                   : jollaStore.categoryName(category)
        }

        delegate: BackgroundItem {
            id: categoryItem
            width: parent.width
            Label {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                text: jollaStore.categoryName(modelData)
                color: categoryItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                truncationMode: TruncationMode.Fade
            }

            onClicked: {
                navigationState.openCategory(modelData, ContentModel.TopNew)
            }

        }

        VerticalScrollDecorator { }
    }
}
