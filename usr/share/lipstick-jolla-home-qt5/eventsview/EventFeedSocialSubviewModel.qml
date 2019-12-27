/****************************************************************************
**
** Copyright (C) 2013-2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
** Contact: Antti Seppälä <antti.seppala@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0

Item {
    id: subviewModel

    property variant model: listModel
    property EventFeedAccountManager manager

    onManagerChanged: refreshAccountModel()

    Connections {
        target: subviewModel.manager
        onRefreshed: refreshAccountModel()
        onAccountEnabledChanged: refreshAccountModel()
    }

    ListModel {
        id: listModel
    }

    function refreshAccountModel() {
        if (!subviewModel.manager || !subviewModel.manager.eventFeedAccounts)
            return

        var i
        var serviceArray = new Array

        // build a list of all active accounts providing supported services
        for (i = 0; i < manager.eventFeedAccounts.length; ++i) {
            var item = manager.eventFeedAccounts[i]
            if (subviewModel.manager.accountEnabledForEventFeeds(item)
                  && serviceArray.indexOf(item.providerName) < 0) {
                 serviceArray.push(item.providerName)
            }
        }

        // create list element for each service not already in the list
        for (i = 0; i < serviceArray.length; ++i) {
            var providerName = serviceArray[i]
            if (!knownService(providerName)) {
                eventsWindowLoader.loadTranslations(providerName)

                // Facebook entries are listed as "Notifications", so show these first to visually
                // group them with ordinary Events notifications. The Twitter feed can be added
                // to the end of the list.
                var insertionIndex = providerName == "facebook" ? 0 : listModel.count
                listModel.insert(insertionIndex, {"providerName": providerName })
            }
        }

        // clean away removed services
        for (i = 0; i < listModel.count; ++i) {
            var account = listModel.get(i)
            if (!inList(serviceArray, account)) {
                listModel.remove(i)
                i--
            }
        }
    }

    function knownService(providerName) {
        for (var i = 0; i < listModel.count; ++i) {
            if (listModel.get(i).providerName === providerName) {
                return true
            }
        }

        return false
    }

    function inList(list, account) {
        for (var i = 0; i < list.length; ++i) {
            if (list[i] === account.providerName) {
                return true
            }
        }

        return false
    }

    function accountList(providerName) {
        var result = new Array
        for (var i = 0; i < subviewModel.manager.eventFeedAccounts.length; ++i) {
            var account = subviewModel.manager.eventFeedAccounts[i]
            if (account.enabled
                  && account.providerName === providerName
                  && subviewModel.manager.accountSupportsEventFeeds(account)) {
                result.push(account)
            }
        }

        return result
    }

    function shouldAutoSyncAccount(accountId) {
        return subviewModel.manager.shouldAutoSyncAccount(accountId)
    }

    Component.onCompleted: refreshAccountModel()
}
