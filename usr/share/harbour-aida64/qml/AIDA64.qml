import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow
{
    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All

    property int horizPageMargin: {
        if (Theme.horizontalPageMargin) return Theme.horizontalPageMargin
        else return Theme.paddingLarge
    }

    Rectangle {
        id: msgRect

        width: parent.width
        height: msgLabel.height + 2 * msgLabel.y

        color: "teal"
        opacity: 1
        visible: false
        y: parent.height - height
        z: 1000

        function showMessage(msg) {
            msgLabel.text = msg
            msgRect.visible = true
            msgTimer.start()
        }

        Label {
            id: msgLabel
            color: "white"
            horizontalAlignment: Text.Center
            x: horizPageMargin
            y: Theme.paddingLarge
            width: parent.width - 2 * x
            wrapMode: Text.Wrap
        }

        Timer {
            id: msgTimer
            interval: 5000
            onTriggered: {
                stop()
                msgRect.visible = false
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                msgTimer.stop()
                msgRect.visible = false
            }
        }
    }
}
