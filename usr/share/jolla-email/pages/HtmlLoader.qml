/*
 * Copyright (c) 2014 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Nemo.Email 0.1
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0
import Nemo.Configuration 1.0

Loader {
    id: htmlLoader

    property bool showLoadProgress: true
    readonly property int pageStatus: messageViewPage.status
    property bool portrait
    property bool isOutgoing
    property bool isLocalFile
    property string initialAction
    readonly property bool showImages: app.accountsManagerActive || downloadImagesConfig.value

    property bool _wasLoaded
    property var _html
    property var _email
    property AttachmentListModel attachmentsModel

    signal removeRequested
    signal needToSendReadReceipt

    function load(email) {
        if (email.contentType === EmailMessage.Plain) {
            parser.text = email.body
            _html = Qt.binding(plainTextAsHtml)
        } else {
            _html = email.htmlBody
            parser.text = ""
        }

        _email = email

        if (initialAction) {
            _openComposer(initialAction, email, true)
            initialAction = ""
        }

        _finishLoad()
    }

    function _finishLoad() {
        if (!item) {
            // Show progress indicator when we don't have an item.
            showLoadProgress = true
            messageViewPage.loaded = false
            active = true
        } else {
            if (!_html.length)
                return

            _wasLoaded = true
            loadingTimer.restart()
        }
    }

    function markAsRead() {
        if (_email) {
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
            active = true
        }

        _finishLoad()
    }

    function plainTextAsHtml() {
        return "<html><body><div style=\"white-space: pre-wrap; word-wrap: break-word;\">" + parser.linkedText + "</div></body></html>"
    }

    function _openComposer(action, immediately) {
        pageStack.animatorPush(
                    Qt.resolvedUrl("ComposerPage.qml"),
                    { popDestination: previousPage, action: action, originalMessageId: _email.messageId },
                    immediately ? PageStackAction.Immediate : PageStackAction.Animated)
    }

    Component.onCompleted: {
        WebEngineSettings.autoLoadImages = Qt.binding(function() {
            return showImages
        })
    }

    sourceComponent: HtmlViewer {
        anchors.fill: parent
        interactive: messageViewPage.loaded
        portrait: htmlLoader.portrait
        attachmentsModel: htmlLoader.attachmentsModel
        isOutgoing: htmlLoader.isOutgoing
        isLocalFile: htmlLoader.isLocalFile
        email: htmlLoader._email
        htmlBody: htmlLoader._html
        showImages: htmlLoader.showImages

        onVisuallyCommittedChanged: {
            if (visuallyCommitted) {
                showLoadProgress = false
                if (pageStatus == PageStatus.Active && (!loadingTimer.running || loaded)) {
                    messageViewPage.loaded = true
                    loadingTimer.stop()
                }
            }
        }

        onComposerRequested: htmlLoader._openComposer(action, false)
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
            _finishLoad()
        }
    }

    asynchronous: true


    LinkParser {
        id: parser
    }

    ConfigurationValue {
        id: downloadImagesConfig
        key: "/apps/jolla-email/settings/downloadImages"
        defaultValue: false
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
