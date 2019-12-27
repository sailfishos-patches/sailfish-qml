import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root

    property real bytes
    property real total
    property bool valid: total > 0
    property alias color: labelBytes.color

    readonly property real _bytes: Math.max(bytes, 0)

    height: Math.max(column.height + 2*Theme.paddingSmall, Theme.itemSizeSmall)
    enabled: false

    Column {
        id: column

        x: Theme.horizontalPageMargin
        width: parent.width - 2*x
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.paddingSmall

        Item {
            height: label.height
            width: parent.width

            Label {
                id: label
                text: model.label
                color: labelBytes.color
                width: parent.width - labelBytes.width - Theme.paddingMedium
                wrapMode: Text.Wrap
            }

            Label {
                id: labelBytes
                anchors.right: parent.right
                text: valid ? Format.formatFileSize(_bytes) : ""
                color: highlighted || !root.enabled ? Theme.highlightColor : Theme.primaryColor
                opacity: valid ? 1 : 0
                Behavior on opacity { FadeAnimation { } }
            }
        }

        Rectangle {
            height: Math.round(Theme.paddingLarge/3)
            width: Math.max(Math.round(Theme.paddingSmall), valid ? parent.width * (_bytes / total) : 0)
            Behavior on width { PropertyAnimation { duration: 200; easing.type: Easing.InOutQuad } }
            color: colors[model.index % colors.length]
        }
    }
}
