import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

/* Item representing an application in a grid.
 */
BackgroundItem {
    id: gridItem
    property alias title: titleLabel.text
    property alias author: authorLabel.text
    property string appCover
    property string appIcon
    property int appState: ApplicationState.Normal
    property int progress: 100
    property int likes
    property bool androidApp

    implicitHeight: Math.max(appImage.height, labelColumn.height) + 2 * Theme.paddingMedium

    AppImage {
        id: appImage
        anchors {
            left: parent.left
            leftMargin: Theme.paddingMedium
            verticalCenter: parent.verticalCenter
        }
        width: appGridIconSize
        height: appGridIconSize
        image: appIcon
        opacity: busyIndicator.running ? Theme.opacityFaint : 1.0
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: appImage
        running: appState === ApplicationState.Uninstalling ||
                 appState === ApplicationState.Installing ||
                 appState === ApplicationState.Updating
    }

    Column {
        id: labelColumn

        anchors {
            left: appImage.right
            leftMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.paddingSmall
            verticalCenter: parent.verticalCenter
        }

        Label {
            id: titleLabel
            width: parent.width
            color: gridItem.highlighted ? Theme.highlightColor : Theme.primaryColor
            font.pixelSize: appGridFontSize
            truncationMode: TruncationMode.Fade
        }

        Label {
            id: authorLabel
            width: parent.width
            color: Theme.secondaryHighlightColor
            font.pixelSize: appGridFontSize
            truncationMode: TruncationMode.Fade
        }

        Item {
            width: parent.width
            height: likesLabel.height

            Label {
                id: likesLabel
                anchors {
                    left: parent.left
                    right: statusIcon.visible ? statusIcon.left : parent.right
                    rightMargin: statusIcon.visible ? Theme.paddingSmall : 0
                }
                color: gridItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: appGridFontSize
                truncationMode: TruncationMode.Fade
                //: Number of likes in application grid item. Takes number of likes as a parameter.
                //% "%n like(s)"
                text: qsTrId("jolla-store-la-app_grid_likes", likes)
            }

            Image {
                id: statusIcon
                anchors {
                    right: parent.right
                    verticalCenter: likesLabel.verticalCenter
                }
                source: appState === ApplicationState.Installed
                        ? "image://theme/icon-s-installed"
                        : appState === ApplicationState.Updatable
                          ? "image://theme/icon-s-update"
                          : androidApp
                            ? "image://theme/icon-s-android-label"
                            : ""
            }
        }
    }
}
