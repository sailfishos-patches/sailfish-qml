import QtQuick 2.0
import Sailfish.Silica 1.0

ContextMenu {
    id: menu

    property string avatarUrl
    property bool updateOnClose
    property var avatarUrlModel

    signal updateAvatarMenu()
    signal avatarFromGallery()
    signal setAvatarPath(string path)

    onHeightChanged: {
        if (height == 0 && updateOnClose) {
            root._updateAvatarMenu()
            updateOnClose = false
        }
    }

    MenuItem {
        //: Select avatar from gallery
        //% "Select from gallery"
        text: qsTrId("components_contacts-me-avatar_gallery")
        onClicked: avatarFromGallery()
    }

    Repeater {
        model: avatarUrlModel

        Item {
            property bool down
            property bool highlighted
            property int __silica_menuitem

            signal clicked

            width: menu.width
            height: avatarImage.height + 2*Theme.paddingSmall

            Image {
                id: avatarImage
                width: Theme.itemSizeLarge
                height: width
                x: (parent.width - width) / 2
                y: Theme.paddingSmall
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                source: model.url
            }

            onClicked: setAvatarPath(modelData)
        }
    }

    MenuItem {
        //: Remove avatar
        //% "No image"
        text: qsTrId("components_contacts-me-avatar_remove")
        visible: avatarUrl != ''
        onClicked: {
            // Set an empty path to override other images
            setAvatarPath('')
        }
    }
}
