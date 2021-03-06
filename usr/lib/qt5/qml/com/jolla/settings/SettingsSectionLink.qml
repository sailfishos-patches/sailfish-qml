import QtQuick 2.0
import Sailfish.Silica 1.0

SettingItem {
    id: root

    property alias name: label.text
    property url iconSource
    property int depth

    implicitHeight: Math.max(Theme.itemSizeSmall, label.height + 2 * Theme.paddingMedium)

    onClicked: {
        pageStack.animatorPush("SettingsPage.qml", {
                                   "name": root.name,
                                   "entryPath": root.entryPath,
                                   "depth": root.depth
                               })
    }

    Image {
        id: icon
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        source: (root.highlighted && root.iconSource)
                ? root.iconSource + "?" + Theme.highlightColor
                : root.iconSource
    }
    Label {
        id: label
        truncationMode: TruncationMode.Fade
        color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        anchors {
            left: icon.right
            leftMargin: icon.width > 0 ? Theme.paddingMedium : 0
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
    }
}
