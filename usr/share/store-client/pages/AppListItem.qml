import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

/* Item representing an application in a list.
 */

ListItem {
    id: listItem

    property alias title: titleLabel.text
    property alias icon: lineIcon.image
    property int progress: 100
    property string version
    property int appState

    function statusText() {
        if (progress === 0) {
            //: Waiting status text for an application item
            //% "Waiting"
            return qsTrId("jolla-store-la-waiting")
        } else if (progress < 50) {
            //: Downloading status text for an application item
            //% "Downloading"
            return qsTrId("jolla-store-la-downloading")
        } else if (progress < 100) {
            return appState == ApplicationState.Installing
                    //: Installing status text for an application item
                    //% "Installing"
                    ? qsTrId("jolla-store-la-installing")
                    //: Updating status text for an application item
                    //% "Updating"
                    : qsTrId("jolla-store-la-updating")
        }
        return ""
    }


    AppImage {
        id: lineIcon

        visible: listItem.progress === 0 || listItem.progress === 100
        width: height
        height: Theme.iconSizeLauncher
        anchors {
            left: parent.left
            leftMargin: Theme.paddingLarge
            verticalCenter: parent.verticalCenter
        }
    }

    BusyIndicator {
        visible: !lineIcon.visible
        anchors.centerIn: lineIcon
        running: visible
    }

    Column {
        anchors {
            left: lineIcon.right
            right: parent.right
            margins: Theme.paddingLarge
            verticalCenter: parent.verticalCenter
        }

        Label {
            id: titleLabel
            width: parent.width
            truncationMode: TruncationMode.Fade
            font.pixelSize: Theme.fontSizeSmall
            color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        }

        Label {
            visible: text !== ""
            width: parent.width
            font.pixelSize: Theme.fontSizeExtraSmall
            text: statusText()
            color: listItem.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
    }
}
