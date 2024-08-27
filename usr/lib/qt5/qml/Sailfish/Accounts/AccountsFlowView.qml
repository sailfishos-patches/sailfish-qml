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

Flow {
    id: root

    //-------------- api

    property alias filterType: accountModel.filterType
    property alias filter: accountModel.filter
    property alias model: accountModel
    property bool entriesInteractive
    property real itemWidth: width
    property int deletingAccountId

    signal accountClicked(int accountId, string providerName)
    signal accountRemoveRequested(int accountId)
    signal accountSyncRequested(int accountId)

    //-------------- impl

    property bool _hideJollaAccount

    // We don't want the height to change when the Page is hidden, so
    // latch the height when visible
    property real _visibleHeight
    onImplicitHeightChanged: if (visible) _visibleHeight = implicitHeight
    height: _visibleHeight

    Repeater {
        model: AccountModel { id: accountModel }

        delegate: AccountsListDelegate {
            id: delegateItem

            hidden: deletingAccountId === model.accountId
            width: root.itemWidth

            enabled: root.entriesInteractive

            visible: !root._hideJollaAccount || model.providerName !== "jolla"
            entriesInteractive: root.entriesInteractive
            allowRemoveOnly: !model.providerValid

            onAccountSyncRequested: root.accountSyncRequested(accountId)
            onAccountRemoveRequested: root.accountRemoveRequested(accountId)
            onAccountClicked: root.accountClicked(accountId, providerName)
        }
    }

    AccountSyncManager {
        id: accountSyncManager
    }

    AccountManager { id: accountManager }
    VerticalScrollDecorator {}
}
