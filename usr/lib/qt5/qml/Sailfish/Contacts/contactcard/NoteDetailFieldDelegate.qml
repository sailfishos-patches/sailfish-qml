import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.TextLinking 1.0

Column {
    id: root

    property bool highlighted
    property alias value: contactDetailValue.plainText
    property alias metadata: contactDetailMetadata.text
    readonly property bool collapsed: contactDetailValue.implicitHeight > contactDetailValue.height

    signal contentResized(var item, var newItemHeight)

    function expand() {
        if (!expandAnim.running) {
            showMoreButton.visible = false
            root.contentResized(contactDetailValue, contactDetailValue.implicitHeight + metaDataContainer.height)
            expandAnim.start()
        }
    }

    NumberAnimation {
        id: expandAnim

        target: contactDetailValue
        property: "height"
        to: contactDetailValue.implicitHeight
        easing.type: Easing.InOutQuad
        duration: 300
    }

    visible: value.length > 0
    width: parent.width

    LinkedText {
        id: contactDetailValue

        width: parent.width
        height: Math.min(implicitHeight, detailFontMetrics.height * 4)  // Show at most 4 lines initially

        color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        linkColor: root.highlighted ? Theme.primaryColor : Theme.highlightColor
        font.pixelSize: Theme.fontSizeMedium
        horizontalAlignment: Text.AlignLeft
        clip: root.collapsed
    }

    FontMetrics {
        id: detailFontMetrics
        font: contactDetailValue.font
    }

    Item {
        id: metaDataContainer

        width: parent.width
        height: contactDetailMetadata.height

        Label {
            id: contactDetailMetadata

            color: root.highlighted ? Theme.highlightColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            truncationMode: TruncationMode.Fade
        }

        ShowMoreButton {
            id: showMoreButton

            anchors {
                left: contactDetailMetadata.right
                leftMargin: Theme.paddingLarge
                right: parent.right
                verticalCenter: contactDetailMetadata.verticalCenter
            }

            horizontalAlignment: Text.AlignRight
            visible: root.collapsed
            enabled: false
            highlighted: root.highlighted
        }
    }
}
