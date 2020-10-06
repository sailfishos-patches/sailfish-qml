/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.5
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1
import org.nemomobile.systemsettings 1.0

UserItem {
    id: userSelector

    property bool menuOpen
    property var currentUser

    height: menuOpen && topMenu.contextMenu ? contentHeight + topMenu.contextMenu.height : contentHeight
    textHighlighted: highlighted || menuOpen
    name: currentUser.displayName
    type: currentUser.type
    uid: currentUser.uid

    onClicked: {
        if (Lipstick.compositor.topMenuLayer.housekeeping) {
            Lipstick.compositor.topMenuLayer.housekeeping = false
        } else {
            settingsContainer.openMenu(userSelectionMenuComponent, userSelector)
        }
    }

    onPressAndHold: settingsContainer.openMenu(userOptionsMenuComponent, userSelector)

    Component {
        id: userSelectionMenuComponent

        ContextMenu {
            id: userSelectionMenu

            container: topMenu.parent
            // Allows to scroll top menu even when this context menu is open
            VerticalAutoScroll.modal: false

            onClosed: userSelectionMenu.destroy()
            Component.onCompleted: userSelector.menuOpen = true
            Component.onDestruction: userSelector.menuOpen = false

            Repeater {
                model: UserModel {
                    id: userModel
                }

                delegate: UserItem {
                    contentHeight: Theme.itemSizeMedium
                    height: contentHeight
                    highlighted: down || current
                    name: displayName
                    type: model.type
                    uid: model.uid
                    showYou: true
                    width: parent.width

                    onClicked: {
                        if (current) {
                            userSelectionMenu.close()
                        } else {
                            userModel.setCurrentUser(index)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: userOptionsMenuComponent

        ContextMenu {
            id: userOptionsMenu

            container: topMenu.parent
            onClosed: userOptionsMenu.destroy()
            Component.onCompleted: userSelector.menuOpen = true
            Component.onDestruction: userSelector.menuOpen = false

            MenuItem {
                //% "Add new user"
                text: qsTrId("lipstick_jolla_home-me-topmenu_add_new_user")
                onClicked: favoriteSettingsLoader.showAddNewUser()
                visible: currentUser.type == UserInfo.DeviceOwner
            }

            MenuItem {
                //% "Go to Users settings"
                text: qsTrId("lipstick_jolla_home-me-topmenu_users_settings")
                onClicked: favoriteSettingsLoader.showUsersSettings()
            }
        }
    }
}
