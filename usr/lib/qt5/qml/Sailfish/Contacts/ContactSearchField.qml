import QtQuick 2.0
import Sailfish.Silica 1.0

SearchField {
    id: root

    width: parent.width

    //: Search contacts list
    //% "Search people"
    placeholderText: qsTrId("components_contacts-ph-search_people")

    // avoid removing focus whenever a contact is added to the selection list
    focusOutBehavior: FocusBehavior.KeepFocus

    autoScrollEnabled: false

    EnterKey.iconSource: "image://theme/icon-m-enter-close"
    EnterKey.onClicked: focus = false
}
