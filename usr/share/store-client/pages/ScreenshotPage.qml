import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private

FullscreenContentPage {
    id: page

    property alias model: slideshow.model
    property alias currentIndex: slideshow.currentIndex

    SlideshowView {
        id: slideshow

        anchors.fill: parent
        itemWidth: width

        delegate: Item {
            width: slideshow.itemWidth
            height: slideshow.height

            Behavior on opacity { FadeAnimation {} }

            StoreImage {
                id: screenshot
                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                smooth: true
                image: modelData

                Rectangle {
                    visible: parent.status !== Image.Ready
                    anchors.fill: parent
                    color: Theme.rgba(Theme.primaryColor, Theme.opacityFaint)
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    pageStack.pop()
                }
            }
        }
    }

    Private.DismissButton {}
}
