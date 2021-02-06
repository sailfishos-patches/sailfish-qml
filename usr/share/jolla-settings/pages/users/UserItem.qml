/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0

ListItem {
    id: userItem

    readonly property bool creating: placeholder && root.creatingUser
    readonly property bool deleting: !placeholder && transitioning
    readonly property bool deviceOwner: type === UserModel.DeviceOwner
    readonly property bool guestUser: type === UserModel.Guest
    readonly property real positionOffset: deviceOwner ? Theme.fontSizeMedium/2 : 0

    clip: true
    contentHeight: Theme.paddingMedium + nameEditor.height
    Behavior on contentHeight {
        enabled: !pageStack.busy
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    openMenuOnPressAndHold: !nameEditor.editing && !placeholder && !transitioning && (root.admin || !current)

    onClicked: {
        if (!nameEditor.editing && !transitioning) {
            if (!root.admin && current && !guestUser) {
                rename()
            } else if (!placeholder && (root.admin || !current)) {
                openMenu()
            }
        }
    }

    onCreatingChanged: {
        if (creating) {
            deviceLockQuery.askCode(function() { rename() },
                                    function() { root.creatingUser = false })
        }
    }

    function rename() {
        nameEditor.editing = true
        nameEditor.forceActiveFocus()
    }

    menu: Component {
        ContextMenu {
            MenuItem {
                //% "Switch to user"
                text: qsTrId("settings_users-me-switch_to_user")
                visible: !current
                onClicked: userModel.setCurrentUser(index)
            }

            MenuItem {
                // Re-evaluated if groups update, i.e. _groupUpdateCounter changes value
                readonly property bool hasAccess: userList._groupUpdateCounter,
                                                  userModel.hasGroup(index, "sailfish-phone")
                                               || userModel.hasGroup(index, "sailfish-messages")

                text: hasAccess
                    //% "Turn off calls and SMS"
                    ? qsTrId("settings_users-me-turn_off_calls_and_sms")
                    //% "Turn on calls and SMS"
                    : qsTrId("settings_users-me-turn_on_calls_and_sms")
                visible: root.admin && !deviceOwner
                onClicked: {
                    if (hasAccess) {
                        userModel.removeGroups(index, ["sailfish-phone", "sailfish-messages"]);
                    } else {
                        userModel.addGroups(index, ["sailfish-phone", "sailfish-messages"]);
                    }
                }
            }

            MenuItem {
                //% "Rename"
                text: qsTrId("settings_users-me-rename")
                visible: root.admin && !guestUser
                onClicked: rename()
            }

            MenuItem {
                //% "Delete"
                text: qsTrId("settings_users-me-delete")
                visible: root.admin && !deviceOwner && !guestUser
                onClicked: root.remove(index, displayName)
            }
        }
    }

    InverseMouseArea {
        anchors.fill: parent
        enabled: nameEditor.editing
        onClickedOutside: nameEditor.save()
    }

    Item {
        anchors {
            left: parent.left
            right: parent.right
        }
        height: userItem.contentHeight

        MouseArea {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: nameEditor.left
                top: parent.top
            }
            enabled: nameEditor.editing
            onClicked: nameEditor.cursorPosition = 0
        }

        UserIcon {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            x: Theme.horizontalPageMargin

            color: {
                if (highlighted) {
                    return highlightColor
                } else if (placeholder) {
                    return "#FFFFFF"
                } else {
                    return userColor
                }
            }
            highlighted: userItem.highlighted
            opacity: placeholder || transitioning ? 0.5 : 1.0

            type: model.type
            uid: model.uid
        }

        Label {
            id: youLabel
            anchors {
                left: icon.right
                leftMargin: Theme.paddingSmall
                top: nameEditor.top
                topMargin: Theme.paddingSmall
            }
            //: "You" means the current user, %1 is a bullet character
            //% "You %1 "
            text: qsTrId("settings_users-la-you").arg("\u2022")
            visible: current
            width: visible ? contentWidth : 0
        }

        TextField {
            id: nameEditor

            property bool editing
            readonly property bool canSave: acceptableInput && text.length > 0
            property int minimumHeight

            function save() {
                cursorPosition = 0
                disableEditing.start()
                if (canSave) {
                    name = text
                    if (placeholder) {
                        deviceLockQuery.askCode(function() {
                            userModel.createUser()
                            focus = false
                        })
                    }
                } else if (placeholder && text.length == 0) {
                    root.creatingUser = false
                }
            }

            anchors {
                left: youLabel.right
                right: disablePhoneIcon.left
                rightMargin: disablePhoneIcon.visible ? Theme.paddingSmall : 0
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: Theme.paddingSmall - userItem.positionOffset
            }
            background: null
            enabled: editing
            focusOutBehavior: FocusBehavior.KeepFocus
            highlighted: userItem.highlighted || (placeholder && activeFocus)
            labelVisible: false
            // We want to show normally fully opaque text, breaks opacity binding to enabled
            opacity: deleting ? 0.5 : 1.0
            //: Input field for the name of the new user (it can be anything, full name is expected)
            //% "New user name"
            placeholderText: placeholder ? qsTrId("settings_users-ph-new_user_name") : ""
            readOnly: !editing
            text: displayName
            textMargin: 0
            inputMethodHints: Qt.ImhNoPredictiveText
            validator: RegExpValidator { regExp: /\w[\w\.\- ]*|/ }

            // Allow names to span over multiple lines if there is no activeFocus
            height: Math.max(implicitHeight, minimumHeight)
            textWidth: {
                if (!activeFocus) {
                    return width
                } else if (_editor.implicitWidth < _minimumWidth) {
                    return _minimumWidth
                } else {
                    return _editor.implicitWidth
                }
            }
            wrapMode: !activeFocus ? TextInput.Wrap : TextInput.NoWrap

            onActiveFocusChanged: minimumHeight = implicitHeight

            onPressAndHold: if (userItem.openMenuOnPressAndHold) userItem.openMenu()

            EnterKey.enabled: canSave
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: save()

            Timer {
                id: disableEditing
                interval: 0
                repeat: false
                onTriggered: nameEditor.editing = false
            }
        }

        Icon {
            id: disablePhoneIcon
            anchors {
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                verticalCenter: parent.verticalCenter
            }
            source: "image://theme/icon-s-disabled-phone"
            // Re-evaluated if groups update, i.e. _groupUpdateCounter changes value
            enabled: userList._groupUpdateCounter, !placeholder
                                       && !userModel.hasGroup(index, "sailfish-phone")
                                       && !userModel.hasGroup(index, "sailfish-messages")
                                       && index != -1
            visible: enabled
            width: enabled ? implicitWidth : 0
        }

        MouseArea {
            anchors {
                bottom: parent.bottom
                left: disablePhoneIcon.left
                right: parent.right
                top: parent.top
            }
            enabled: nameEditor.editing
            onClicked: nameEditor.cursorPosition = nameEditor.text.length
        }

        Label {
            anchors {
                left: icon.right
                leftMargin: Theme.paddingSmall
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: userItem.positionOffset
            }
            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
            //% "Admin"
            text: qsTrId("settings_users-la-admin")
            visible: deviceOwner
        }
    }
}
