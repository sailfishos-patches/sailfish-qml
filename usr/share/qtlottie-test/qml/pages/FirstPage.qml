import QtQuick 2.0
import Sailfish.Silica 1.0
import Qt.labs.lottieqt 1.0

Page {
    id: page

    function lottieSelected(filename) {
        qtlottie.stop()
        qtlottie.source = filename
        qtlottie.gotoAndPlay(0)
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: "QtLottie Test"
            }
        }
    }

    LottieAnimation {
        id: qtlottie
        anchors.centerIn: parent
        autoPlay: true
        frameRate: 30

        onStatusChanged: {
            console.log(status)
            if (status == LottieAnimation.Ready) {
                progress.maximumValue = getDuration(true)
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.itemSizeLarge
        color: Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)

        Item {
            height: parent.height
            width: parent.width

            IconButton {
                id: playButton
                anchors.left: parent.left
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "image://theme/icon-m-play"
                onClicked: {
                    qtlottie.stop()
                    qtlottie.gotoAndPlay(0)
                }
            }

            Slider {
                id: progress
                anchors.left: playButton.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                minimumValue: 0
                stepSize: 1
                onValueChanged: {
                    qtlottie.gotoAndStop(value)
                }
            }
        }
    }
}
