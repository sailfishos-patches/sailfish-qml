import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

Image {
    readonly property bool loaded: status === Image.Ready

    clip: true
    height: width
    width: Theme.iconSizeMedium
    fillMode: Image.PreserveAspectCrop
    sourceSize.width: width
    source: notification && notification.hints["image-path"]
            ? Notifications.iconSource(notification.hints["image-path"], silicaItem.palette.primaryColor)
            : ""

    SilicaItem {
        id: silicaItem
    }
}
