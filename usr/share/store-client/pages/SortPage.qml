import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

Page {
    signal selected(int sortType)

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width

            PageHeader {
                //: Page header for the Sort by page
                //% "Sort by"
                title: qsTrId("jolla-store-he-sort_by")
            }

            SortItem {
                //: Sort by time
                //% "Latest"
                text: qsTrId("jolla-store-me-sort_latest")
                onClicked: selected(ContentModel.TopNew)
            }

            SortItem {
                //: Sort by number of likes
                //% "Most liked"
                text: qsTrId("jolla-store-me-sort_most_liked")
                onClicked: selected(ContentModel.TopLiked)
            }

            SortItem {
                //: Sort by number of downloads
                //% "Most downloaded"
                text: qsTrId("jolla-store-me-sort_most_downloaded")
                onClicked: selected(ContentModel.TopDownloaded)
            }
        }
    }
}
