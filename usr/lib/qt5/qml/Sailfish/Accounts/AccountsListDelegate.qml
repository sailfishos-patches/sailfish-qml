/****************************************************************************************
** Copyright (c) 2015 - 2023 Jolla Ltd.
**
** All rights reserved.
**
** This file is part of Sailfish Accounts components package.
**
** You may use this file under the terms of BSD license as follows:
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**
** 1. Redistributions of source code must retain the above copyright notice, this
**    list of conditions and the following disclaimer.
**
** 2. Redistributions in binary form must reproduce the above copyright notice,
**    this list of conditions and the following disclaimer in the documentation
**    and/or other materials provided with the distribution.
**
** 3. Neither the name of the copyright holder nor the names of its
**    contributors may be used to endorse or promote products derived from
**    this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
** AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
** FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
** DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
** SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
** CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
** OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**
****************************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0

ListItem {
    id: delegateItem
    property bool entriesInteractive
    property bool allowRemoveOnly

    readonly property bool notSignedIn: model.accountError === AccountModel.AccountNotSignedInError
    readonly property bool valid: notSignedIn || model.accountError === AccountModel.NoAccountError

    signal accountRemoveRequested(int accountId)
    signal accountSyncRequested(int accountId)
    signal accountClicked(int accountId, string providerName)

    contentHeight: visible
                   ? Math.max(icon.height, column.height + (errorLabel.visible ? errorLabel.height : 0)) + 2*Theme.paddingSmall
                   : 0
    menu: entriesInteractive ? menuComponent : null

    Component {
        id: menuComponent

        ContextMenu {
            MenuLabel {
                text: {
                    if (model.accountReadOnly && model.accountLimited) {
                        //: Displayed if the account is read-only and limited
                        //% "Account is read-only and limited"
                        return qsTrId("components_accounts-la-account_read_only_limited")
                    }
                    if (model.accountReadOnly) {
                        //: Displayed if the account is read-only
                        //% "Account is read-only"
                        return qsTrId("components_accounts-la-account_read_only")
                    }
                    //: Displayed if the account is limited
                    //% "Account is limited"
                    return qsTrId("components_accounts-la-account_limited")
                }
                visible: model.accountReadOnly || model.accountLimited
            }
            MenuItem {
                visible: model.providerName !== "jolla" && !model.accountReadOnly && !model.accountLimited && !delegateItem.allowRemoveOnly
                text: model.accountEnabled
                        //: Disables a user account
                        //% "Disable"
                      ? qsTrId("components_accounts-me-disable")
                        //: Enables a user account
                        //% "Enable"
                      : qsTrId("components_accounts-me-enable")
                onClicked: {
                    accountModel.setAccountEnabled(model.accountId, !accountEnabled)
                }
            }

            MenuItem {
                visible: !model.accountReadOnly && !model.accountLimited
                //: Deletes a user account
                //% "Delete"
                text: qsTrId("components_accounts-me-delete_account")
                onClicked: removeAccount()
            }

            MenuItem {
                //: Syncs the data for this account
                //% "Sync"
                text: qsTrId("components_accounts-me-sync")
                visible: !notSignedIn && model.accountEnabled
                         && (model.providerName === "activesync" || accountSyncManager.profileIds(model.accountId).length > 0)
                         && !delegateItem.allowRemoveOnly

                onClicked: {
                    delegateItem.accountSyncRequested(model.accountId)
                }
            }
        }
    }

    function removeAccount() {
        remorseDelete(function() { delegateItem.accountRemoveRequested(model.accountId) })
    }

    ListView.onRemove: animateRemoval()

    Binding {
        target: icon
        property: "opacity"
        when: !delegateItem.highlighted // don't change the opacity while the context menu is open
        value: model.accountEnabled && !syncIndicator.running ? 1.0 : 0.3
    }

    AccountIcon {
        id: icon
        x: Theme.horizontalPageMargin
        y: Math.max(Theme.paddingSmall, -height / 2 + column.y + column.height / 2)
        source: model.accountIcon
    }
    BusyIndicator {
        id: syncIndicator
        anchors.centerIn: icon
        size: BusyIndicatorSize.Small
        height: width
        running: model.performingInitialSync && model.accountError === AccountModel.NoAccountError
    }
    Column {
        id: column
        anchors {
            left: icon.right
            leftMargin: Theme.paddingLarge
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: errorLabel.visible ? -(errorLabel.height/2) : 0
        }
        Label {
            width: parent.width
            truncationMode: TruncationMode.Fade
            text: model.accountDisplayName
            color: {
                if (highlighted || !valid) {
                    return Theme.highlightColor
                }
                return model.accountEnabled
                        ? Theme.primaryColor
                        : Theme.rgba(Theme.primaryColor, 0.55)
            }
        }
        Label {
            width: parent.width
            visible: text.length > 0
            truncationMode: TruncationMode.Fade
            text: {
                if (model.performingInitialSync) {
                    //: In the process of setting up this account
                    //% "Setting up account..."
                    return qsTrId("component_accounts-la-setting_up_account")
                }
                return model.accountUserName
            }
            color: {
                if (highlighted || !valid) {
                    return Theme.secondaryHighlightColor
                }
                return model.accountEnabled
                        ? Theme.secondaryColor
                        : Theme.rgba(Theme.secondaryColor, 0.3)
            }
        }
    }

    Label {
        id: errorLabel
        anchors {
            left: icon.right
            leftMargin: Theme.paddingLarge
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            top: column.bottom
        }

        width: parent.width
        visible: notSignedIn
        truncationMode: TruncationMode.Fade
        color: Theme.errorColor
        //: The user has not logged into this account
        //% "Account not signed in"
        text: qsTrId("component_accounts-la-not_signed_in2")
        font.pixelSize: Theme.fontSizeSmall
    }

    onClicked: {
        if (allowRemoveOnly) {
            openMenu()
        } else {
            delegateItem.accountClicked(model.accountId, model.providerName)
        }
    }
}
