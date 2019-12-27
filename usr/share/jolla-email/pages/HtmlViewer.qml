/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import QtWebKit 3.0
import QtWebKit.experimental 1.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import Nemo.Email 0.1
import org.nemomobile.configuration 1.0

SilicaWebView {
    id: webView

    property EmailMessage email
    property string htmlBody
    // Basically meaning that
    // html text emails will get scaled up by factor (1.5*Theme.pixelRatio) rounded to nearest half.
    // With higher scale factor content layouts starts touching edges of WebView and that hinders
    // legibility. Thus, this 1.5 base factor.
    property double _scale: Math.round((1.5 * Theme.pixelRatio) / .5) * .5

    // Avoid blocking webview content during accounts creation
    readonly property bool showImages: app.accountsManagerActive || downloadImagesConfig.value
    property bool showImagesButton
    property int showImagesMessageId
    property bool loaded
    property bool portrait
    property AttachmentListModel attachmentsModel
    property bool isOutgoing
    property bool isLocalFile

    property bool visuallyCommitted

    signal removeRequested

    function hasViewportMetaTag(html) {
        // Opening < will be chopped away as it's not meaningful
        var headStart = html.indexOf("head")
        // Closing </ will be left in head (with possible whitespace)
        var headEnd = html.indexOf("head", headStart + 4)
        // Look like head>...</ (whitespaces for opening and closing head handled later
        var head = html.slice(headStart, headEnd)
        // WebKit handles viewport case insensitively (HTMLMetaElemant.cpp)
        return head.search(/viewport/i) !== -1
    }

    function _updateLayout(width) {
        // Respect viewport meta tag if exists
        if (!hasViewportMetaTag(htmlBody)) {
            // This affects only to layouts that do not have width defined in body content.
            // Smaller content layout gets scaled up to WebView's width.
            experimental.customLayoutWidth = width / _scale
        } else {
            experimental.customLayoutWidth = width
        }
        // reload html
        loadHtml(htmlBody, "file:///usr/share/jolla-email")
    }

    function setHtml(html) {
        htmlBody = html
        _updateLayout(width)
    }

    onWidthChanged: {
        _updateLayout(width)
    }

    onLoadingChanged: {
        // Not 100% sure but looks like that offline API limits loadProgress to reach 100%.
        // Instead of loadProgress 100, loadRequest.status LoadSoppedStatus is emitted. When image loading
        // is enabled, loading succeeds normally.
        if ((loadRequest.status === WebView.LoadSucceededStatus || loadRequest.status === WebView.LoadStoppedStatus)
                && htmlBody) {
            loaded = true
        }
    }

    onLoadProgressChanged: {
        if (loadProgress === 100 && htmlBody) {
            loaded = true
        }
    }

    onLoadedChanged: {
        if (loaded) {
            visuallyCommittedTimer.restart()
        }
    }

    experimental.overview: true
    experimental.preferences.javascriptEnabled: false
    experimental.offline: !showImages

    experimental.userStyleSheets: [ Qt.resolvedUrl("htmlViewer.css") ]

    header: MessageViewHeader {
        width: webView.width
        email: webView.email

        isOutgoing: webView.isOutgoing
        attachmentsModel: webView.attachmentsModel
        portrait: webView.portrait
        showLoadImages: webView.showImagesButton

        function loadImages() {
            webView.showImagesButton = false
            experimental.offline = false
            showImagesMessageId = email.messageId
        }
        onLoadImagesClicked: loadImages()
    }

    // Load image banner is set on the first ignored request
    experimental.onNetworkRequestIgnored: {
        // ID 0 is invalid => don't load by default, otherwise
        // If the message is the same and user already accepted
        // the load of images, just proceed
        if (email.messageId !== 0 && showImagesMessageId === email.messageId) {
            webView.showImagesButton = false
            experimental.offline = false
        } else if (!showImagesButton) {
            showImagesButton = true
        }
    }

    experimental.onOfflineChanged: {
        if (!experimental.offline && !showImagesButton) {
            // reload html
            setHtml(htmlBody)
        }
    }

    onEmailChanged: showImagesButton = false

    onHtmlBodyChanged: {
        if (!htmlBody) {
            return
        }
        visuallyCommitted = false
        loaded = false

        // Change the preference before loading new html body
        showImagesButton = false
        experimental.offline = !showImages
        setHtml(htmlBody)
    }

    onNavigationRequested: {
        switch (request.navigationType)
        {
        case WebView.OtherNavigation:
        case WebView.ReloadNavigation: {
            request.action = WebView.AcceptRequest
            return
        }
        default:
            // Disallow navigating outside
            request.action = WebView.IgnoreRequest
        }
    }

    onLinkHovered: linkHandler.handleLink(hoveredUrl)

    experimental.onLoadVisuallyCommitted: {
        visuallyCommitted = true
        visuallyCommittedTimer.stop()
    }

    // When jumping from email to email onLoadVisuallyCommit does
    // not always get triggered. This is here to guarantee that
    // shown gets emitted.
    Timer {
        id: visuallyCommittedTimer

        interval: 800
        onTriggered: visuallyCommitted = true
    }

    LinkHandler {
        id: linkHandler
    }

    VerticalScrollDecorator { color: Theme.highlightBackgroundColor }
    HorizontalScrollDecorator { color: Theme.highlightBackgroundColor }

    MessageViewPullDown {
        onRemoveRequested: webView.removeRequested()
        visible: !webView.isLocalFile
    }

    ConfigurationValue {
        id: downloadImagesConfig
        key: "/apps/jolla-email/settings/downloadImages"
        defaultValue: false
    }
}
