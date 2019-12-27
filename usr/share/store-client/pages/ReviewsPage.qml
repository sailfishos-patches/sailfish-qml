import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

Page {
    id: page
    objectName: "ReviewsPage"

    property string appUuid
    property string appAuthor
    property string packageVersion

    ReviewModel {
        id: reviewModel
        store: jollaStore
        application: appUuid
    }

    PageHeader {
        id: pageHeader
        //: Page header for the comments page
        //% "Comments"
        title: qsTrId("jolla-store-he-comments")
    }

    SilicaListView {
        id: listview

        anchors.fill: parent
        anchors.topMargin: pageHeader.height
        verticalLayoutDirection: ListView.BottomToTop
        clip: true
        model: reviewModel

        header: ReviewEditor {
            width: listview.width
            appUuid: page.appUuid
            packageVersion: page.packageVersion
        }

        footer: Item {
            visible: reviewModel.loading
            width: listview.width
            height: visible ? Theme.itemSizeMedium : 0

            BusyIndicator {
                anchors.centerIn: parent
                running: parent.visible
                size: BusyIndicatorSize.Medium
            }
        }

        delegate: ReviewItem {
            width: listview.width

            uuid: model.uuid
            appUuid: page.appUuid
            authorName: model.authorName
            review: model.review
            version: normalizeVersion(model.version)
            createdOn: model.createdOn
            updatedOn: model.updatedOn
            isAppAuthor: model.author === appAuthor
            isSelf: model.author === jollaStore.user
            packageVersion: page.packageVersion
        }

        VerticalScrollDecorator { }

    }
}
