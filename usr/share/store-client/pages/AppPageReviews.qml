import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import org.pycage.jollastore 1.0

Item {
    id: appPageReviews
    property ApplicationData app
    property int horizontalMargin: Theme.horizontalPageMargin

    width: parent.width
    height: reviewsColumn.height
    visible: app.inStore

    ReviewModel {
        id: reviewModel

        store: jollaStore
        application: app.application
        // We only show max 3 comments, but need to fetch 4 so that we know
        // whether to show the "more" button or not.
        limit: 4
    }

    Column {
        id: reviewsColumn
        width: parent.width
        // There's no bottom-to-top column so need to fake it by
        // rotating the column and the items inside it.
        rotation: 180

        ReviewEditor {
            width: parent.width
            horizontalMargin: appPageReviews.horizontalMargin
            rotation: 180
            appUuid: app.application
            packageVersion: page.packageVersion
        }

        Item {
            visible: reviewModel.loading || reviewModel.count === 0

            width: parent.width
            height: busyReviews.height + 2 * Theme.paddingMedium + Theme.paddingSmall
            rotation: 180

            BusyIndicator {
                id: busyReviews
                visible: reviewModel.loading
                         && jollaStore.isOnline
                anchors.centerIn: parent
                running: true
            }

            Label {
                visible: jollaStore.isOnline
                         && !reviewModel.loading
                         && reviewModel.count === 0
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: horizontalMargin
                    verticalCenter: parent.verticalCenter
                }
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryHighlightColor
                //: No comments text
                //% "No comments yet"
                text: qsTrId("jolla-store-li-no_comments")
            }

            Label {
                id: offlineErrorLabel
                visible: !jollaStore.isOnline
                         && reviewModel.count === 0
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: horizontalMargin
                    verticalCenter: parent.verticalCenter
                }
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                color: tryGoOnline.pressed ? Theme.secondaryHighlightColor : Theme.secondaryColor
                //: Text shown when comments cannot be loaded because the device is offline
                //% "Cannot load comments while offline."
                text: qsTrId("jolla-store-li-no_comments_offline")
            }

            MouseArea {
                id: tryGoOnline
                anchors.fill: parent
                enabled: offlineErrorLabel
                onClicked: jollaStore.tryGoOnline()
            }
        }

        Repeater {
            model: reviewModel

            delegate: ReviewItem {
                width: column.width
                horizontalMargin: appPageReviews.horizontalMargin
                rotation: 180
                visible: model.index < 3

                uuid: model.uuid
                appUuid: app.application
                authorName: model.authorName
                review: model.review
                version: normalizeVersion(model.version)
                createdOn: model.createdOn
                updatedOn: model.updatedOn
                isAppAuthor: model.author === app.user
                isSelf: model.author === jollaStore.user
                packageVersion: page.packageVersion
            }
        }

        MoreButton {
            id: moreCommentsButton
            width: parent.width
            height: Theme.itemSizeMedium
            horizontalMargin: appPageReviews.horizontalMargin
            enabled: reviewModel.count > 3
            rotation: 180

            //: Comments action button label.
            //% "Comments"
            text: qsTrId("jolla-store-li-comments")

            onClicked: {
                navigationState.openReview(app.application, app.user, page.packageVersion)
            }
        }
    }
}
