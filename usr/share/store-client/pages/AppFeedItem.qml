import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

/* Item representing an application in a grid.
 */
AppBackgroundItem {
    id: feedItem

    property string uuid
    property alias title: titleLabel.text
    property alias text: textLabel.text
    property alias appTitle: appTitleLabel.text
    property string appIcon
    property int appState: ApplicationState.Normal
    property int progress: 100
    property int itemType
    property bool androidApp

    width: parent.width
    height: Theme.paddingMedium + titleLabel.height +
            (textLabel.visible ? (textLabel.height + Theme.paddingSmall) : 0) +
            Theme.paddingMedium + appImage.height + Theme.paddingSmall +
            appTitleLabel.height + Theme.paddingLarge
    gradientOpacity: 0.25

    Rectangle {
        anchors.centerIn: parent
        width: parent.height
        height: parent.width
        rotation: 90
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.rgba(Theme.highlightBackgroundColor, 0.1) }
            GradientStop { position: 0.2; color: "transparent" }
        }
    }

    Image {
        id: icon
        anchors {
            verticalCenter: titleLabel.verticalCenter
            right: parent.right
            rightMargin: Theme.paddingMedium
        }
        source: {
            var src = "image://theme/icon-"
            if (itemType === Feed.Like) {
                src += "s-like"
            } else if (itemType === Feed.Comment) {
                src += "s-chat"
            } else if (itemType === Feed.New) {
                src += "s-new"
            } else {
                src += "m-jolla"
            }
            src += "?" + Theme.highlightColor
            return src
        }
    }

    Label {
        id: titleLabel
        anchors {
            top: parent.top
            topMargin: Theme.paddingMedium
            left: parent.left
            leftMargin: Theme.paddingLarge
            right: icon.left
            rightMargin: Theme.paddingSmall
        }
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeExtraSmall
        truncationMode: TruncationMode.Fade
    }

    Label {
        id: textLabel
        visible: text !== "" && itemType !== Feed.Like
        anchors {
            top: titleLabel.bottom
            topMargin: Theme.paddingSmall
            left: parent.left
            leftMargin: Theme.paddingLarge
            right: parent.right
            rightMargin: Theme.paddingLarge
        }
        color: feedItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeExtraSmall
        wrapMode: Text.Wrap
        maximumLineCount: 3
    }

    AppImage {
        id: appImage
        anchors {
            bottom: appTitleLabel.visible ? appTitleLabel.top : parent.bottom
            bottomMargin: appTitleLabel.visible ? Theme.paddingSmall : Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        width: Theme.iconSizeLauncher
        height: width
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

    Label {
        id: appTitleLabel
        visible: itemType !== Feed.Promo
        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        width: Math.min(implicitWidth, parent.width - 2 * (Theme.paddingSmall + statusIcon.width + Theme.paddingMedium))
        color: feedItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeTiny
        truncationMode: TruncationMode.Fade
    }

    Image {
        id: statusIcon
        anchors {
            right: parent.right
            rightMargin: Theme.paddingMedium
            verticalCenter: appTitleLabel.verticalCenter
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
