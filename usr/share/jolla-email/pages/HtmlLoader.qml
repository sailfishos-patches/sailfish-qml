/*
 * Copyright (c) 2014 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import Nemo.Email 0.1

Loader {
    id: htmlLoader

    property bool showLoadProgress: true
    readonly property int pageStatus: messageViewPage.status
    property bool portrait
    property bool isOutgoing
    property bool isLocalFile

    property bool _wasLoaded
    property bool _wasOffline
    property bool _wasImagesLoaded
    property var _html
    property var _email
    property AttachmentListModel attachmentsModel

    signal removeRequested
    signal needToSendReadReceipt

    function load(html, email) {
        // Needed for resurrecting the HtmlViewer
        _html = html
        _email = email

        // Show progress indicator when we don't have an item.
        if (!item) {
            showLoadProgress = true
            messageViewPage.loaded = false
        }

        if (!item) {
            active = true
        } else {
            if (email) {
                item.email = email
            }

            if (!html.length)
                return

            _wasLoaded = true
            item.setHtml(html)
            loadingTimer.restart()
        }
    }

    function markAsRead() {
        if (item && _email) {
            if (!_email.read && _email.requestReadReceipt) {
                needToSendReadReceipt()
            }
            _email.read = true
        }
    }

    function resurrect() {
        // Don't resurrect if item was not never loaded or we already
        // have an item (nothing was released).
        if (!_wasLoaded || item) {
            return
        }

        if (!item) {
            // Loader is async. Let's do not depend directly on the _wasOffline
            _wasImagesLoaded = !_wasOffline
            active = true
        }

        load(_html, _email)
    }

    sourceComponent: HtmlViewer {
        anchors.fill: parent
        contentWidth: parent.width
        interactive: messageViewPage.loaded
        portrait: htmlLoader.portrait
        attachmentsModel: htmlLoader.attachmentsModel
        isOutgoing: htmlLoader.isOutgoing
        isLocalFile: htmlLoader.isLocalFile

        onVisuallyCommittedChanged: {
            if (visuallyCommitted) {
                showLoadProgress = false
                if (!_email.read && _email.requestReadReceipt) {
                    needToSendReadReceipt()
                }
                _email.read = true
                if (pageStatus == PageStatus.Active && (!loadingTimer.running || loaded)) {
                    messageViewPage.loaded = true
                    loadingTimer.stop()
                }
            }
        }

        onRemoveRequested: htmlLoader.removeRequested()
    }

    // Activated from load()
    active: false
    onActiveChanged: {
        if (!active) {
            messageViewPage.loaded = false
        }
    }

    onItemChanged: {
        if (item) {
            // Resurrect image loading state.
            if (_wasImagesLoaded) {
                item.showImagesButton = false
                item.experimental.offline = false
                item.showImagesMessageId = _email && _email.messageId || 0
            }
            _wasImagesLoaded = false
            load(_html, _email)
        }
    }

    asynchronous: true

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: messageViewPage.isLandscape ? Theme.itemSizeSmall : Theme.itemSizeLarge

        color: "white"
        z: 1

        visible: !item || !item.visuallyCommitted

        // Filter mouse presses to the "Show images"
        MouseArea {
            anchors.fill: parent
            enabled: parent.visible
        }

        BusyIndicator {
            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
            running: parent.visible
        }
    }

    Timer {
        id: loadingTimer
        interval: 800
        onTriggered: {
            if (pageStatus == PageStatus.Active) {
                messageViewPage.loaded = true
            }
        }
    }

    Timer {
        id: backgroundTimer

        readonly property bool canRelease: !Qt.application.active && htmlLoader.item

        interval: 1000 * 10 // 10sec
        onTriggered: {
            if (canRelease) {
                _wasOffline = htmlLoader.item.experimental.offline
                htmlLoader.active = false
            }
        }

        onCanReleaseChanged: {
            if (canRelease) {
                restart()
            }
        }
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active) {
                backgroundTimer.stop()
                htmlLoader.resurrect()
            }
        }
    }
}
