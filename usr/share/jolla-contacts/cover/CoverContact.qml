import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import Nemo.Thumbnailer 1.0

Thumbnail {
    id: coverContact

    property var contact
    property bool center
    property bool enableAvatar: true
    property color backgroundColor
    property real backgroundOpacity
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
            backgroundOpacity = 0.0
        } else {
            source = ""
            firstText = contact.primaryName
            secondText = contact.secondaryName
            backgroundOpacity = 0.0
        }
    }

    onEnableAvatarChanged: displayData()
    onContactChanged: displayData()

    sourceSize {
        width: AvatarSize.thumbnailSize
        height: AvatarSize.thumbnailSize
    }

    Rectangle {
        visible: color !== "" && opacity > 0
        anchors.fill: parent
        color: coverContact.backgroundColor
        opacity: coverContact.backgroundOpacity
    }

    Loader {
        anchors.fill: parent
        source: firstText !== "" || secondText !== "" ? "CoverName.qml" : ""
    }

    ContactPresenceIndicator {
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
