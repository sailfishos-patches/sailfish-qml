/****************************************************************************
**
** Copyright (C) 2014-2015 Jolla Ltd.
** Contact: Antti Seppälä <antti.seppala@jollamobile.com>
**
****************************************************************************/
import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Nemo.Connectivity 1.0
import Nemo.DBus 2.0
import org.nemomobile.socialcache 1.0
import QtQml.Models 2.1
import org.nemomobile.lipstick 0.1

Item {
    id: item

    property alias headerText: headerItem.name
    property string headerIcon
    property alias showHeaderItemCount: headerItem.showTotalItemCount
    property alias delegate: delegateModel.delegate
    property alias model: delegateModel.model

    property alias socialNetwork: syncHelper.socialNetwork
    property alias dataType: syncHelper.dataType
    property var services: []

    property bool showingInActiveView
    // ALL other connectedToNetwork properties in other pages
    // are bound to this property, directly or indirectly.
    property alias connectedToNetwork: connectionHelper.online
    property int refreshTimeCount: 1 // Increment this to trigger feed items to refresh times.

    // This is bound to "collapsed" value in lipstick-jolla-home and notifies us when user-expanded
    // lists should be automatically collapsed
    property bool collapsed: true
    property SocialImageCache downloader
    property string providerName
    property Item subviewModel
    property int animationDuration

    property int expansionThreshold: 5
    property int expansionMaximum: 10
    property string expandedLabel
    property bool userRemovable
    property bool hasRemovableItems: userRemovable && model.count > 0
    property alias mainContentHeight: listView.contentHeight
    property bool removeAllInProgress
    property bool hasSyncableAccounts

    property real eventsColumnMaxWidth

    signal headerClicked()
    signal expandedClicked()
    signal expanded(int itemPosY)

    function findMatchingRemovableItems(filterFunc, matchingResults) {
        if (!userRemovable || !filterFunc(headerItem)) {
            return
        }
        matchingResults.push(headerItem)
        var yPos = listView.contentY
        while (yPos < listView.contentHeight) {
            var item = listView.itemAt(0, yPos)
            if (!item) {
                break
            }
            if (item.userRemovable === true) {
                if (!filterFunc(item)) {
                    return false
                }
                matchingResults.push(item)
            }
            yPos += item.height
        }
    }

    function removeAllNotifications() {
        if (userRemovable && model) {
            removeAllInProgress = true
            model.clear()
            removeAllInProgress = false
        }
    }

    property int _prevCount: -1
    property QtObject _addAnimation
    property QtObject _removeAnimation
    property bool _needToSync
    property bool _manuallyExpanded
    property var _syncableAccountProfiles: []

    width: parent.width
    height: model.count == 0 ? 0 : expansionToggle.y + expansionToggle.height
    opacity: 0
    enabled: model.count > 0

    Component.onCompleted: {
        // prefill view with initial content
        if (model) {
            resetHasSyncableAccounts()
            model.refresh()
        }
    }

    onConnectedToNetworkChanged: {
        if (connectedToNetwork && _needToSync) {
            _needToSync = false
            sync()
        }
    }

    onCollapsedChanged: {
        if (!collapsed) {
            item._manuallyExpanded = false
        }
    }

    SyncHelper {
        id: syncHelper
        dataType: SocialSync.Posts
        onLoadingChanged: {
            if (!loading) {
                if (item.model) {
                    item.model.refresh()
                }
            }
        }
    }

    ConnectionHelper {
        id: connectionHelper
    }

    NotificationGroupHeader {
        id: headerItem

        property int pauseBeforeRemoval

        indicator.iconSource: item.headerIcon
        indicator.busy: syncHelper.loading

        memberCount: totalItemCount
        totalItemCount: item.model.count
        userRemovable: item.userRemovable
        animationDuration: item.animationDuration

        onRemoveRequested: {
            if (item.model) {
                item.model.clear()
            }
        }

        onTriggered: {
            headerClicked()
        }
    }

    ListView {
        id: listView
        anchors.top: headerItem.bottom
        width: parent.width
        height: Screen.height * 1000 // Ensures the view is fully populated without needing to bind height: contentHeight
        model: delegateModel
        interactive: false
    }

    NotificationExpansionButton {
        id: expansionToggle
        y: headerItem.height + listView.contentHeight

        title: !item._manuallyExpanded ? defaultTitle : item.expandedLabel
        expandable: item.model.count > expansionThreshold

        onClicked: {
            if (!item._manuallyExpanded) {
                var itemPosY = listView.contentHeight + headerItem.height - Theme.paddingLarge
                item._manuallyExpanded = true
                item.expanded(itemPosY)
            } else {
                item.expandedClicked()
            }
        }
    }

    DBusInterface {
        id: syncInterface
        service: "com.meego.msyncd"
        path: "/synchronizer"
        iface: "com.meego.msyncd"
    }

    BoundedModel {
        id: delegateModel
        maximumCount: item._manuallyExpanded ? item.expansionMaximum : item.expansionThreshold
    }

    // Increases refreshTimeCount once per minute, which triggers timestamp string refresh
    Timer {
        interval: 60000
        repeat: true
        running: item.model.count > 0
        onTriggered: item.refreshTimeCount++
    }

    Connections {
        target: item.model
        onCountChanged: {
            if (item._prevCount <= 0 && item.model.count > 0) {
                if (!item._addAnimation) {
                    item._addAnimation = addAnimationComponent.createObject(item)
                }
                item.enabled = true
                item._addAnimation.start()
                refreshTimeCount++
            } else if (item._prevCount > 0 && item.model.count == 0) {
                if (!item._removeAnimation) {
                    item._removeAnimation = removeAnimationComponent.createObject(item)
                }
                item.enabled = false
                item._removeAnimation.start()
            }
            item._prevCount = item.model.count
        }
    }

    Component {
        id: addAnimationComponent

        NotificationAddAnimation {
            target: item
            toHeight: expansionToggle.y + expansionToggle.height
            animationDuration: item.animationDuration
        }
    }

    Component {
        id: removeAnimationComponent

        SequentialAnimation {
            PauseAnimation {
                duration: headerItem.pauseBeforeRemoval
            }
            NotificationRemoveAnimation {
                target: item
                animationDuration: item.animationDuration
            }
        }
    }

    function resetHasSyncableAccounts() {
        var accountIds = []
        item._syncableAccountProfiles = []
        var accounts = subviewModel.accountList(item.providerName)
        for (var i = 0; i < accounts.length; ++i) {
            accountIds.push(accounts[i].identifier)
            if (!subviewModel.shouldAutoSyncAccount(accounts[i].identifier)) {
                continue
            }
            for (var j = 0; j < item.services.length; ++j) {
                var perAccountProfile = item.providerName + "." + item.services[j] + "-" + accounts[i].identifier
                item._syncableAccountProfiles.push(perAccountProfile)
            }
        }
        model.accountIdFilter = accountIds
        item.hasSyncableAccounts = item._syncableAccountProfiles.length > 0
    }

    function sync() {
        if (item.connectedToNetwork) {
            for (var i = 0; i< item._syncableAccountProfiles.length; ++i) {
                syncInterface.call("startSync", item._syncableAccountProfiles[i])
            }
        } else {
            if (item.model) {
                // we may have old data in the database anyway.
                // attempt to refresh the list model with that data.
                item.model.refresh()
            }

            // queue a sync for when (if) it succeeds.
            item._needToSync = true
        }
    }
}
