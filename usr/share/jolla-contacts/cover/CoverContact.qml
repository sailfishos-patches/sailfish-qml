import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0

Image {
    id: root
    fillMode: Image.PreserveAspectCrop
    clip: true // otherwise paintedWidth/Height can vary.
    asynchronous: true

    property variant contact
    property bool center: false
    property bool enableAvatar: true
    property color backgroundColor
    property real backgroundOpacity: 0.0
    property string firstText
    property string secondText

    function displayData() {
        if (!contact)
            return

        if (contact.backgroundColor && contact.backgroundOpacity) {
            backgroundColor = contact.backgroundColor
            backgroundOpacity = contact.backgroundOpacity
        } else if (enableAvatar && contact.avatarUrl != '') {
            // Using != as comparator is intentional to avoid constructing a JavaScript string object
            source = contact.avatarUrl
            firstText = ""
            secondText = ""
        } else {
            source = ""
            firstText = contact.primaryName
            secondText = contact.secondaryName
        }
    }

    onEnableAvatarChanged: displayData()
    onContactChanged: displayData()

    Rectangle {
        visible: backgroundColor !== "" && backgroundOpacity > 0
        anchors.fill: parent
        color: root.backgroundColor
        opacity: root.backgroundOpacity
    }

    Loader {
        anchors.fill: parent
        source: firstText !== "" || secondText !== "" ? "CoverName.qml" : ""
    }

    ContactPresenceIndicator {
        id: presence
        visible: !offline
        anchors {
            left: parent.left
            leftMargin: Theme.paddingMedium
            bottom: parent.bottom
            bottomMargin: Theme.paddingMedium
        }
        presenceState: contact.presenceState
        opacity: Theme.opacityHigh
    }
}
