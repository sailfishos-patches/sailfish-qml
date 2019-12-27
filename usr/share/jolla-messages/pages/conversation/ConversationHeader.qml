import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: conversationHeader

    property alias text: conversationTitle.text
    property alias showPhoneIcon: contactPhoneIcon.visible

    width: parent.width
    implicitHeight: Theme.itemSizeLarge

    BackgroundItem {
        id: contactNameBackground

        width: contactNameRow.width + contactNameRow.anchors.rightMargin + Theme.paddingMedium
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        highlighted: down || pageStack._pageStackIndicator.forwardIndicatorDown
        Binding {
            when: conversationHeader.enabled
            target: pageStack._pageStackIndicator
            property: "forwardIndicatorHighlighted"
            value: pageStack._pageStackIndicator.forwardIndicatorDown || contactNameBackground.down
        }

        onClicked: pageStack.navigateForward()

        Row {
            id: contactNameRow

            spacing: Theme.paddingMedium
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
                rightMargin: Theme.paddingMedium * 2 + Theme.paddingSmall
            }

            Label {
                id: conversationTitle

                property int limitedWidth: conversationHeader.width
                                           - (contactPhoneIcon.visible ? (contactPhoneIcon.width + contactNameRow.spacing) : 0)
                                           - contactNameRow.anchors.rightMargin
                                           - Theme.paddingMedium - 2 * Theme.paddingLarge

                color: contactNameBackground.highlighted ? Theme.highlightColor : Theme.primaryColor
                width: Math.min(implicitWidth, limitedWidth)
                truncationMode: TruncationMode.Fade
                anchors.verticalCenter: parent.verticalCenter
                font {
                    pixelSize: Theme.fontSizeLarge
                    family: Theme.fontFamilyHeading
                }
            }

            HighlightImage {
                id: contactPhoneIcon

                highlighted: contactNameBackground.highlighted
                anchors.verticalCenter: parent.verticalCenter
                source: "image://theme/icon-m-contact"
            }
        }
    }
}
