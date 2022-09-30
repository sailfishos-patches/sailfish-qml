/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.AccessControl 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.devicelock 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: root

    readonly property bool admin: AccessControl.hasGroup(AccessControl.RealUid, "sailfish-system")
    property bool creatingUser
    property bool enableUserCreationOnceComplete
    property UserModel userModel: userModel

    function remove(index, name) {
        var index = index
        var obj = pageStack.animatorPush(deleteUserDialog, { name: name })
        obj.pageCompleted.connect(function(dialog) {
            dialog.accepted.connect(function() {
                if (dialog.acceptDestinationInstance) {
                    dialog.acceptDestinationInstance.authenticate(deviceLockSettings.authorization, function() {
                        userModel.removeUser(index)
                    })
                } else {
                    userModel.removeUser(index)
                }
            })
        })
    }

    function enableUserCreation() {
        if (!deviceLockQuery._availableMethods) {
            var obj = pageStack.animatorPush(enableCodeConfirmation)
            obj.pageCompleted.connect(function(dialog) {
                dialog.accepted.connect(function() {
                    dialog.acceptDestinationInstance.authenticate()
                    dialog.acceptDestinationInstance.canceled.connect(function() {
                        pageStack.pop(root)
                    })
                    dialog.acceptDestinationInstance.authenticated.connect(function() {
                        deviceLockQuery.cachedAuth = true
                        root.creatingUser = true
                        pageStack.pop(root)
                    })
                })
            })
        } else {
            deviceLockQuery.askCode(function() {
                root.creatingUser = true
            })
        }
    }

    UserModel {
        id: userModel
        placeholder: admin && count < maximumCount

        onUserAddFailed: {
            switch (error) {
                case UserModel.HomeCreateFailed:
                    //% "Home directory already in use, please try another name"
                    Notices.show(qsTrId("settings_users-la-adding_user_failed_home_create_failed"))
                    break
                case UserModel.GroupCreateFailed:
                    //% "User group already in use, please try another name"
                    Notices.show(qsTrId("settings_users-la-adding_user_failed_group_create_failed"))
                    break
                case UserModel.UserAddFailed:
                    //% "Could not add user, please try another name"
                    Notices.show(qsTrId("settings_users-la-adding_user_failed_user_add_failed"))
                    break
                case UserModel.MaximumNumberOfUsersReached:
                    //% "Could not add user, maximum number of users reached already"
                    Notices.show(qsTrId("settings_users-la-maximum_number_of_users_reached"))
                    break
                case UserModel.UserModifyFailed:
                case UserModel.Failure:
                default:
                    //% "Could not add user"
                    Notices.show(qsTrId("settings_users-la-adding_user_failed"))
                    break
            }
            root.creatingUser = false
        }

        onUserModifyFailed: {
            //% "Could not rename user"
            Notices.show(qsTrId("settings_users-la-renaming_user_failed"))
        }

        onUserRemoveFailed: {
            switch (error) {
                case UserModel.HomeRemoveFailed:
                    //% "Could not remove user, home directory could not be removed"
                    Notices.show(qsTrId("settings_users-la-home_remove_failed"))
                    break
                case UserModel.UserRemoveFailed:
                case UserModel.Failure:
                default:
                    //% "Could not remove user"
                    Notices.show(qsTrId("settings_users-la-removing_user_failed"))
                    break
            }
        }

        onAddGroupsFailed: {
            //% "Could not add permissions"
            Notices.show(qsTrId("settings_users-la-add_permissions_failed"))
        }

        onRemoveGroupsFailed: {
            //% "Could not remove permissions"
            Notices.show(qsTrId("settings_users-la-remove_permissions_failed"))
        }

        onUserGroupsChanged: userList._groupUpdateCounter++

        onRowsInserted: root.creatingUser = false
    }

    DeviceLockQuery {
        id: deviceLockQuery

        property bool active: Qt.application.active
        property bool cachedAuth
        readonly property bool codeRequired: deviceLockQuery._availableMethods && !deviceLockQuery.cachedAuth

        onActiveChanged: if (!active) cachedAuth = false
        returnOnAccept: true
        returnOnCancel: true

        function askCode(onAuthenticated, onRejected) {
            if (!cachedAuth) {
                authenticate(deviceLockSettings.authorization, function(token) {
                    cachedAuth = true
                    onAuthenticated(true)
                }, onRejected)
            } else {
                onAuthenticated(false)
            }
        }
    }

    DeviceLockSettings {
        id: deviceLockSettings

        authorization {
            onChallengeExpired: {
                deviceLockSettings.authorization.requestChallenge()
            }
        }
    }

    SilicaListView {
        id: userList

        property int _groupUpdateCounter

        anchors.fill: parent
        model: userModel

        PullDownMenu {
            visible: root.admin

            MenuItem {
                text: userModel.guestEnabled
                        //% "Hide guest user"
                        ? qsTrId("settings_users-me-hide_guest")
                        //% "Show guest user"
                        : qsTrId("settings_users-me-show_guest")
                onClicked: {
                    userModel.setGuestEnabled(!userModel.guestEnabled)
                }
            }
        }

        header: Column {
            bottomPadding: Theme.paddingLarge
            width: parent.width

            PageHeader {
                //% "Users"
                title: qsTrId("settings_users-he-users")
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
                color: Theme.highlightColor
                opacity: userModel.count > 1 ? 1.0 : Theme.opacityLow
                //% "Switch between users easily from Top menu, opened via a swipe from top of the display."
                text: qsTrId("settings_users-la-user_switch_help")
                wrapMode: Text.Wrap
            }
        }

        delegate: Item {
            id: listItem
            height: userItem.implicitHeight
            width: ListView.view.width

            ListView.onAdd: AddAnimation { target: placeholder && !root.creatingItem ? addButtonLoader : userItem }

            ListView.onRemove: userItem.animateRemoval(listItem)

            function updateGroups() {
                userItem._groupUpdateCounter++
            }

            UserItem {
                id: userItem
                Behavior on opacity { FadeAnimator { } }
            }

            Loader {
                id: addButtonLoader
                anchors.fill: parent
                active: placeholder
                Behavior on opacity { FadeAnimator { } }

                sourceComponent: Component {
                    ListItem {
                        contentHeight: parent ? parent.height : 0

                        onClicked: root.enableUserCreation()

                        Icon {
                            id: addIcon
                            anchors.verticalCenter: parent.verticalCenter
                            source: "image://theme/icon-m-add"
                            x: Theme.horizontalPageMargin
                        }

                        Label {
                            anchors {
                                left: addIcon.right
                                leftMargin: Theme.paddingSmall
                                right: parent.right
                                rightMargin: Theme.horizontalPageMargin
                                verticalCenter: parent.verticalCenter
                            }
                            highlighted: parent.highlighted
                            //% "Add user"
                            text: qsTrId("settings_users-la-add_user")
                        }
                    }
                }

                states: [
                    State {
                        name: "userItem"
                        when: !placeholder || root.creatingUser
                        PropertyChanges {
                            target: userItem
                            opacity: 1.0
                        }
                        PropertyChanges {
                            target: addButtonLoader
                            opacity: 0.0
                        }
                    },
                    State {
                        name: "addButton"
                        when: placeholder && !root.creatingUser
                        PropertyChanges {
                            target: addButtonLoader
                            opacity: 1.0
                        }
                        PropertyChanges {
                            target: userItem
                            opacity: 0.0
                        }
                    }
                ]
            }
        }

        VerticalScrollDecorator { }
    }

    Component {
        id: enableCodeConfirmation

        Dialog {

            acceptDestination: "com.jolla.settings.system.MandatoryDeviceLockInputPage"
            acceptDestinationAction: PageStackAction.Replace
            acceptDestinationProperties: {
                "authorization": deviceLockSettings.authorization
            }

            Component.onCompleted: deviceLockSettings.authorization.requestChallenge()

            SilicaFlickable {
                contentHeight: content.height
                anchors.fill: parent

                Column {
                    id: content
                    width: parent.width
                    spacing: Theme.paddingLarge

                    DialogHeader {
                        id: header
                    }

                    Label {
                        id: topic
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * x
                        font.pixelSize: Theme.fontSizeExtraLarge
                        color: Theme.highlightColor
                        wrapMode: Text.Wrap
                        //% "Security code required"
                        text: qsTrId("settings_users_la-security_required")
                    }

                    Label {
                        id: description
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * x
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.highlightColor
                        wrapMode: Text.Wrap
                        //% "Adding users requires enabling security code to prevent unauthorized changes to the device. Security code cannot be disabled after users have been added."
                        text: qsTrId("settings_users_la-security_description")
                    }
                }

                VerticalScrollDecorator { }
            }
        }
    }

    Component {
        id: deleteUserDialog

        Dialog {
            id: dialog
            property string name

            acceptDestination: deviceLockQuery.codeRequired ? securityCodeDialog : root
            acceptDestinationAction: deviceLockQuery.codeRequired ? PageStackAction.Replace : PageStackAction.Pop
            canAccept: deviceLockSettings.authorization.status == Authorization.ChallengeIssued

            Component.onCompleted: deviceLockSettings.authorization.requestChallenge()

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: content.height

                Column {
                    id: content
                    spacing: Theme.paddingLarge
                    width: parent.width

                    DialogHeader {
                        dialog: dialog
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * x

                        color: Theme.highlightColor
                        font {
                            family: Theme.fontFamilyHeading
                            pixelSize: Theme.fontSizeExtraLarge
                        }
                        //: %1 is user's name
                        //% "Do you really want to delete %1?"
                        text: qsTrId("settings_users-la-delete_user").arg(dialog.name)
                        wrapMode: Text.Wrap
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * x

                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        //% "Accepting this will remove everything the user has stored on the device (e.g. accounts, contacts, messages, documents, photos and other media)."
                        text: qsTrId("settings_users-la-delete_user_warning")
                        wrapMode: Text.Wrap
                    }
                }

                VerticalScrollDecorator { }
            }
        }
    }

    Component {
        id: securityCodeDialog

        DeviceLockInputPage {
            id: page

            property QtObject authorization
            property var authenticatedCallback

            function authenticate(authorization, onAuthenticated) {
                page.authorization = authorization
                page.authenticatedCallback = onAuthenticated
                authenticator.authenticate(page.authorization.challengeCode,
                                           page.authorization.allowedMethods)
            }

            Authenticator {
                id: authenticator

                onAuthenticated: {
                    deviceLockQuery.cachedAuth = true
                    page.authenticatedCallback()
                    pageStack.pop(root)
                }
                onAborted: pageStack.pop(root)
            }
        }
    }

    Component.onCompleted: if (enableUserCreationOnceComplete) enableUserCreation()
}
