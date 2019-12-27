import QtQuick 2.0
import Sailfish.Silica 1.0

// Placeholder that can be shown in several places when offline.
// Use the condition property if you want to have the item appear
// only in a certain condition, additionally to being offline currently.
ViewPlaceholder {
    property bool condition: true

    visible: !jollaStore.isOnline && condition
    enabled: visible
    //: View placeholder when being offline
    //% "Sorry, cannot connect to store right now. Please try again later."
    text: qsTrId("jolla-store-li-being_offline")
}
