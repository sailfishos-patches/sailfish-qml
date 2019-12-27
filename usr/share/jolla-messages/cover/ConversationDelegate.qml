import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0

Item {
    id: root

    width: parent.width
    height: recipientsPositioner.y + recipientsPositioner.height

    property alias messageText: textLayout.text
    property string recipients
    property alias maximumLineCount: textLayout.maximumLineCount
    property bool extraSmall
    property bool needsFading
    readonly property alias lineCount: lines.count
    readonly property bool rightToLeft: Format.textDirection(messageText) == Qt.RightToLeft
    property alias recipientsItem: recipientsPositioner
    property alias messageItem: message
    property int lineHeight: recipientsLabel.height / recipientsLabel.lineCount
    property OpacityRampEffect _opacityRamp

    onNeedsFadingChanged: {
        if (needsFading && !_opacityRamp) {
            _opacityRamp = opacityRampComponent.createObject(recipientsPositioner)
        }
    }

    Column {
        id: message

        width: parent.width

        Repeater {
            id: lines

            property real margin: Theme.paddingMedium

            model: TextLayoutModel {
                id: textLayout

                width: message.width - 2*(Theme.paddingMedium + Theme.paddingSmall)
                font.pixelSize: extraSmall ? Theme.fontSizeExtraSmall : Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            delegate: Item {
                anchors {
                    left: parent && !root.rightToLeft ? parent.left : undefined
                    right: parent && root.rightToLeft ? parent.right : undefined
                    margins: lines.margin
                }
                width: parent ? Math.min(parent.width - 2*lines.margin, model.width + 2*Theme.paddingSmall) : 0
                height: model.height

                Rectangle {
                    width: parent.width
                    y: 1
                    height: parent.height - y
                    radius: Theme.paddingSmall/2
                    color: 'white'
                }

                Label {
                    x: Theme.paddingSmall
                    width: model.width
                    font: textLayout.font
                    textFormat: Text.PlainText
                    text: model.text
                    truncationMode: model.elided ? TruncationMode.Fade : TruncationMode.None
                    maximumLineCount: 1
                    color: 'black'
                }
            }
        }
    }
    Item {
        id: recipientsPositioner

        width: parent.width
        y: message.y + message.height
        height: extraSmall ? (recipientsLabel.height + Theme.paddingSmall - 2)
                           : (recipientsLabel.lineCount == 1 ? recipientsLabel.height*2 : recipientsLabel.height) + Theme.paddingLarge

        Label {
            id: recipientsLabel

            x: Theme.paddingMedium + Theme.paddingSmall
            y: parent.height - height
            width: parent.width - 2*x
            font.pixelSize: extraSmall ? Theme.fontSizeExtraSmall : Theme.fontSizeSmall
            textFormat: Text.PlainText
            wrapMode: extraSmall ? Text.NoWrap : Text.Wrap
            truncationMode: TruncationMode.Fade
            maximumLineCount: extraSmall ? 1 : 2
            text: root.recipients.toUpperCase()
        }
        Component {
            id: opacityRampComponent
            OpacityRampEffect {
                // Use the opacity ramp to ensure the content does not spill into the action area
                enabled: root.needsFading
                direction: OpacityRamp.TopToBottom
                sourceItem: recipientsLabel
                slope: 1
                offset: 1 - 1/slope
            }
        }
    }
}

