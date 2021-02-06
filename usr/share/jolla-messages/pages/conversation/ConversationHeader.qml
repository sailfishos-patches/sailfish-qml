import QtQuick 2.0
import Sailfish.Silica 1.0

PageHeader {
    id: conversationHeader

    property alias text: conversationHeader.title
    property bool showPhoneIcon

    width: parent.width
    rightMargin: showPhoneIcon ? contactPhoneIcon.width + contactPhoneIcon.anchors.rightMargin
                               : Theme.horizontalPageMargin
    interactive: true

    HighlightImage {
        id: contactPhoneIcon

        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }

        visible: showPhoneIcon
        color: conversationHeader.titleColor
        source: "image://theme/icon-m-contact"
    }
}
