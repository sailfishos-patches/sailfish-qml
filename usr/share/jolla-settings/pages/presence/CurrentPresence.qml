import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

CurrentPresenceListItem {
    onClicked: pageStack.animatorPush("PresenceDetails.qml")
    presenceState: PresenceListener.globalPresenceState
}

