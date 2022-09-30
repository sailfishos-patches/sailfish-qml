import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

Column {
    id: welcomeRecommendedItem

    property alias model: feedRepeater.model
    property int columns: 1
    property alias busy: busyIndicator.running

    width: parent.width

    WelcomeBoxBackground {
        width: parent.width
        height: Theme.itemSizeMedium

        Label {
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: icon.left
                rightMargin: Theme.paddingMedium
                verticalCenter: parent.verticalCenter
            }
            horizontalAlignment: Text.AlignRight
            truncationMode: TruncationMode.Fade
            color: Theme.highlightColor
            //: Store editors recommend these apps.
            //% "Recommended for you"
            text: qsTrId("jolla-store-la-recommended_for_you")
        }

        Image {
            id: icon
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
            }
            visible: !busy
            source: "image://theme/icon-m-sailfish?" + Theme.highlightColor
        }

        BusyIndicator {
            id: busyIndicator
            anchors.centerIn: icon
            size: BusyIndicatorSize.Small
        }
    }

    Row {
        id: feedRow

        x: appGridMargin
        visible: !busy

        Repeater {
            id: feedRepeater

            MouseArea {
                id: feedDelegate

                property string feedUuid: model ? model.feedUuid : ""

                width: Math.floor((welcomeRecommendedItem.width - 2 * appGridMargin) / columns)
                height: Math.floor(width / 2)
                visible: index < columns

                AppImage {
                    anchors.fill: parent
                    image: model ? model.cover : ""
                }

                Rectangle {
                    visible: feedDelegate.pressed && feedDelegate.containsMouse
                    anchors.fill: parent
                    color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                }

                onFeedUuidChanged: addAnimation.restart()

                AddAnimation {
                    id: addAnimation
                    target: feedDelegate
                    duration: 500
                }

                onClicked: {
                    if (model.collection !== "") {
                        navigationState.openCategory(model.collection, ContentModel.TopNew)
                    } else {
                        navigationState.openApp(model.uuid, ApplicationState.Normal)
                    }
                }
            }
        }
    }
}
