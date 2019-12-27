import QtQuick 2.0
import Sailfish.Silica 1.0

// Special button that can go along with the OfflinePlaceholder.
// Use the condition property if you want to have the item appear
// only in a certain condition, additionally to being offline currently.
Button {
    property bool condition: true

    visible: !jollaStore.isOnline && condition
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.paddingLarge
    //: Button for retrying to connect to the store after connecting failed.
    //% "Retry"
    text: qsTrId("jolla-store-bt-retry_connect")

    onClicked: {
        if (!jollaStore.isOnline) {
            jollaStore.tryGoOnline()
        } else {
            jollaStore.tryConnect()
        }
    }
}
