import QtQuick 2.2
import QtQuick.Window 2.1 as QtQuick
import Sailfish.Ambience 1.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

Wallpaper {
    id: wallpaper

    property alias ambience: ambience
    property alias applicationBackgroundSourceImage: appBgSourceImage
    property alias applicationBackgroundOverlayImage: appBgOverlayImage
    readonly property bool exposed: transitioning || (background && background.status == Image.Ready)

    textureSize: Qt.size(Screen.height, Screen.height)
    transitionPause: 200

    source: ambience.wallpaperUrl

    visible: Lipstick.compositor.completed && (Lipstick.compositor.homeLayer.wallpaperVisible
                || Lipstick.compositor.lockScreenLayer.exposed)

    Component.onCompleted: Ambience.create(Ambience.source)

    AmbienceInfo {
        id: ambience

        url: Ambience.source
    }

    Image {
        id: appBgSourceImage
        sourceSize: Qt.size(Screen.height, Screen.height)
        visible: false
        source: Theme.backgroundImage
    }

    Image {
        id: appBgOverlayImage;
        source: "image://theme/graphic-shader-texture";
        visible: false
    }

    Item {
        id: ambienceInfo

        anchors.fill: parent

        visible: transitioning || infoAnimation.running
        opacity: transitioning && ambienceLabel.text != "" ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator { id: infoAnimation; duration: 300 } }

        Label {
            id: ambienceLabel
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                bottom: parent.bottom
                bottomMargin: ambienceInfo.height / 8
            }
            color: ambience.highlightColor
            text: ambience.displayName
            font.pixelSize: Theme.fontSizeHuge
            font.family: Theme.fontFamilyHeading
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            maximumLineCount: 5
            wrapMode: Text.Wrap
        }
    }
}
