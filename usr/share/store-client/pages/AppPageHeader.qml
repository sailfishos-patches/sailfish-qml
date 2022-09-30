import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property ApplicationData app
    property int horizontalMargin: Theme.horizontalPageMargin

    property bool _coverAfterDetails: Screen.sizeCategory <= Screen.Medium

    width: parent.width
    height: app.cover === ""
            ? Theme.iconSizeLauncher + 2 * Theme.paddingLarge
            : _coverAfterDetails
              ? coverImage.height + Theme.iconSizeLauncher + 2 * Theme.paddingLarge
              : coverImage.height

    AppImage {
        id: coverImage
        anchors {
            top: _coverAfterDetails ? iconImage.bottom : parent.top
            topMargin: _coverAfterDetails ? Theme.paddingLarge : 0
        }
        width: parent.width
        height: width / 2
        opacity: (imageStatus == Image.Ready || imageStatus == Image.Error) ? 1.0
                                                                            : 0.0
        image: app.cover

        Behavior on opacity { FadeAnimation {} }
    }

    Rectangle {
        width: parent.width
        height: width / 4
        visible: app.cover !== "" && !_coverAfterDetails
        gradient: Gradient {
            GradientStop { position: 0.0; color: "black" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    AppImage {
        id: iconImage
        width: Theme.iconSizeLauncher
        height: width
        anchors {
            right: parent.right
            rightMargin: (app.cover !== "" && !_coverAfterDetails)
                         ? Theme.horizontalPageMargin
                         : horizontalMargin
            top: parent.top
            topMargin: Theme.paddingLarge
        }

        image: app.icon !== "" ? app.icon : "image://theme/icon-store-app-default"
        opacity: (imageStatus == Image.Ready || imageStatus == Image.Error) ? 1.0
                                                                            : 0.0

        Behavior on opacity { FadeAnimation {} }
    }

    Label {
        id: titleLabel
        property int maxWidth: parent.width - Theme.horizontalPageMargin - anchors.rightMargin - iconImage.width - iconImage.anchors.rightMargin

        anchors {
            top: iconImage.top
            right: iconImage.left
            rightMargin: Theme.paddingLarge
        }
        width: Math.min(implicitWidth, maxWidth)
        font.pixelSize: Theme.fontSizeLarge
        font.family: Theme.fontFamilyHeading
        color: Theme.highlightColor
        truncationMode: TruncationMode.Fade
        text: app.title
    }

    Label {
        id: authorLabel
        anchors {
            top: titleLabel.bottom
            right: titleLabel.right
        }
        width: Math.min(implicitWidth, titleLabel.maxWidth)
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.highlightColor
        truncationMode: TruncationMode.Fade
        text: app.authorName
    }
}
