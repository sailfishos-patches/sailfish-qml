/****************************************************************************
 **
 ** Copyright (C) 2014 - 2019 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Sailfish.Lipstick 1.0
import Nemo.Connectivity 1.0
import Nemo.DBus 2.0
import org.nemomobile.socialcache 1.0
import QtQml.Models 2.1

NotificationGroupItem {
    id: root

    property alias headerText: groupHeader.name
    property string headerIcon
    property alias showRemainingCount: expansionToggle.showRemainingCount
    property alias delegate: delegateModel.delegate
    property alias model: delegateModel.model
    property alias boundedModel: delegateModel

    property alias socialNetwork: syncHelper.socialNetwork
    property alias dataType: syncHelper.dataType
    property var services: []

    property bool viewVisible
    // ALL other connectedToNetwork properties in other pages
    // are bound to this property, directly or indirectly.
    property alias connectedToNetwork: connectionHelper.online
    property int refreshTimeCount: 1 // Increment this to trigger feed items to refresh times.

    property SocialImageCache downloader
    property string providerName
    property Item subviewModel

    property int expansionThreshold: 5
    property int expansionMaximum: 10
    property string expandedLabel
    property bool userRemovable
    property bool hasRemovableItems: userRemovable && model.count > 0
    property alias mainContentHeight: listView.contentHeight
    property bool removeAllInProgress
    property bool hasSyncableAccounts
    property bool hasOnlyOneItem: model.count === 1
    property alias contentLeftMargin: groupHeader.textLeftMargin
    property bool collapsed: true

    property real eventsColumnMaxWidth
    property int __account_delegate

    signal headerClicked()
    signal expandedClicked()
    signal expanded(int itemPosY)

    function findMatchingRemovableItems(filterFunc, matchingResults) {
        if (!userRemovable || !filterFunc(groupHeader)) {
            return
        }
        matchingResults.push(groupHeader)
        var yPos = listView.contentY
        while (yPos < listView.contentHeight) {
            var item = listView.itemAt(0, yPos)
            if (!item) {
                break
            }
            if (root.userRemovable === true) {
                if (!filterFunc(item)) {
                    return false
                }
                matchingResults.push(item)
            }
            yPos += root.height
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
    property var _syncableAccountProfiles: []

    height: model.count == 0 ? 0 : expansionToggle.y + expansionToggle.height
    opacity: 0
    enabled: model.count > 0
    draggable: groupHeader.draggable

    Component.onCompleted: {
        // prefill view with initial content
        if (model) {
            resetHasSyncableAccounts()
            model.refresh()
        }
    }

    onSwipedAway: if (model) model.clear()

    onConnectedToNetworkChanged: {
        if (connectedToNetwork && _needToSync) {
            _needToSync = false
            sync()
        }
    }

    SyncHelper {
        id: syncHelper
        dataType: SocialSync.Posts
        onLoadingChanged: {
            if (!loading) {
                if (root.model) {
                    root.model.refresh()
                }
            }
        }
    }

    ConnectionHelper {
        id: connectionHelper
    }

    NotificationGroupHeader {
        id: groupHeader

        property int pauseBeforeRemoval

        onTriggered: headerClicked()

        iconSource: root.headerIcon
        icon.opacity: syncHelper.loading ? Theme.opacityHigh : 1.0
        Behavior on icon.opacity { FadeAnimator {} }

        userRemovable: root.userRemovable
        extraBackgroundPadding: root.hasOnlyOneItem
        groupHighlighted: root.highlighted
        enabled: !housekeeping

        BusyIndicator {
            anchors.verticalCenter: parent.verticalCenter
            size: BusyIndicatorSize.ExtraSmall
            running: syncHelper.loading
        }
    }

    ListView {
        id: listView
        anchors.top: groupHeader.bottom
        width: parent.width
        height: Screen.height * 1000 // Ensures the view is fully populated without needing to bind height: contentHeight
        model: delegateModel
        interactive: false
    }

    NotificationExpansionButton {
        id: expansionToggle
        y: groupHeader.height + listView.contentHeight

        title: root.collapsed ? defaultTitle : root.expandedLabel
        expandable: root.model.count > expansionThreshold
        enabled: expandable && !groupHeader.drag.active
        remainingCount: root.model.count - delegateModel.count

        onClicked: {
            if (root.collapsed) {
                var itemPosY = listView.contentHeight + groupHeader.height - Theme.paddingLarge
                root.collapsed = false
                root.expanded(itemPosY)
            } else {
                root.expandedClicked()
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
        maximumCount: !root.collapsed ? root.expansionMaximum : root.expansionThreshold
    }

    // Increases refreshTimeCount once per minute, which triggers timestamp string refresh
    Timer {
        interval: 60000
        repeat: true
        running: root.model.count > 0
        onTriggered: root.refreshTimeCount++
    }

    Connections {
        target: root.model
        onCountChanged: {
            if (root._prevCount <= 0 && root.model.count > 0) {
                if (!root._addAnimation) {
                    root._addAnimation = addAnimationComponent.createObject(root)
                }
                root.enabled = true
                root._addAnimation.start()
                refreshTimeCount++
            } else if (root._prevCount > 0 && root.model.count == 0) {
                if (!root._removeAnimation) {
                    root._removeAnimation = removeAnimationComponent.createObject(root)
                }
                root.enabled = false
                root._removeAnimation.start()
            }
            root._prevCount = root.model.count
        }
    }

    Component {
        id: addAnimationComponent

        NotificationAddAnimation {
            target: root
            toHeight: expansionToggle.y + expansionToggle.height
        }
    }

    Component {
        id: removeAnimationComponent

        SequentialAnimation {
            PauseAnimation {
                duration: groupHeader.pauseBeforeRemoval
            }
            NotificationRemoveAnimation {
                target: root
            }
        }
    }

    function resetHasSyncableAccounts() {
        var accountIds = []
        root._syncableAccountProfiles = []
        var accounts = subviewModel.accountList(root.providerName)
        for (var i = 0; i < accounts.length; ++i) {
            accountIds.push(accounts[i].identifier)
            if (!subviewModel.shouldAutoSyncAccount(accounts[i].identifier)) {
                continue
            }
            for (var j = 0; j < root.services.length; ++j) {
                var perAccountProfile = root.providerName + "." + root.services[j] + "-" + accounts[i].identifier
                root._syncableAccountProfiles.push(perAccountProfile)
            }
        }
        model.accountIdFilter = accountIds
        root.hasSyncableAccounts = root._syncableAccountProfiles.length > 0
    }

    function sync() {
        if (root.connectedToNetwork) {
            for (var i = 0; i< root._syncableAccountProfiles.length; ++i) {
                syncInterface.call("startSync", root._syncableAccountProfiles[i])
            }
        } else {
            if (root.model) {
                // we may have old data in the database anyway.
                // attempt to refresh the list model with that data.
                root.model.refresh()
            }

            // queue a sync for when (if) it succeeds.
            root._needToSync = true
        }
    }
}
