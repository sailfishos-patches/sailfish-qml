/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.TextLinking 1.0
import Sailfish.WebEngine 1.0
import Sailfish.WebView 1.0
import Nemo.Email 0.1

Item {
    id: view

    property EmailMessage email
    property string htmlBody

    // Avoid blocking webview content during accounts creation
    property bool showImages
    property bool showImagesButton
    property bool portrait
    property AttachmentListModel attachmentsModel
    property bool isOutgoing
    property bool isLocalFile
    property bool hasImages
    property bool orientationTransitionRunning: flickable.webView.webViewPage
                && flickable.webView.webViewPage.orientationTransitionRunning

    property bool pageActive: flickable.webView.webViewPage
            && flickable.webView.webViewPage.status === PageStatus.Active

    property alias interactive: flickable.interactive

    property bool visuallyCommitted
    property bool complete

    signal removeRequested
    signal composerRequested(string action)

    Component.onCompleted: {
        complete = true
    }

    onEmailChanged: showImagesButton = false

    onHtmlBodyChanged: {
        if (!htmlBody) {
            return
        }
        visuallyCommitted = false
        view.showImagesButton = false
        view.hasImages = false

        // Change the preference before loading new html body
        flickable.webView.loadHtml(htmlBody)
    }

    onPageActiveChanged: {
        if (!pageActive) {
            flickable.webView.clearSelection()
        }
    }

    WebViewFlickable {
        id: flickable

        width: view.width
        height: view.height
        // Don't resize the web view when the keyboard is open.
        contentHeight: view.portrait ? Screen.height : Screen.width

        webView {
            x: view.width - webView.width
            width: view.width - landscapeInviteContainer.implicitWidth

            footerMargin: footer.open && !view.isLocalFile ? footer.height : 0

            // Hide the web view while the width changes as there's a lag time between when the
            // QQuickItem resizes and the view refreshes and in the interim the content will appear
            // stretched.
            Behavior on width {
                enabled: view.complete && !view.orientationTransitionRunning
                SequentialAnimation {
                    id: widthChangeAnimation
                    FadeAnimation {
                        target: resizeWhiteout
                        to: 1
                        duration: 100
                    }
                    PropertyAction {}
                    PauseAnimation {
                        duration: 200
                    }
                    FadeAnimation {
                        target: resizeWhiteout
                        to: 0
                        duration: 100
                    }
                }
            }

            Behavior on footerMargin {
                enabled: view.complete && !view.orientationTransitionRunning

                NumberAnimation {
                    id: footerAnimation

                    easing.type: Easing.InOutQuad
                    duration: 100
                }
            }

            onFirstPaint: visuallyCommitted = true

            onViewInitialized: {
                webView.loadFrameScript(Qt.resolvedUrl("webviewframescript.js"));
                webView.addMessageListener("JollaEmail:DocumentHasImages")
                webView.addMessageListener("embed:OpenLink")
            }

            onChromeChanged: {
                if (webView.chrome === footer.open) {
                    // Ignore the change if the values are equal.
                } else if (webView.chrome) {
                    footer.open = true
                } else {
                    footer.open = false
                }
            }


            onTextSelectionActiveChanged: {
                if (webView.textSelectionActive) {
                    footer.open = true
                }
            }

            onRecvAsyncMessage: {
                switch (message) {
                case "JollaEmail:DocumentHasImages":
                    if (!view.hasImages) {
                        view.hasImages = true
                        view.showImagesButton = !view.showImages
                    }
                    break
                case "embed:OpenLink":
                    linkHandler.handleLink(data.uri)
                    break
                default:
                    break
                }
            }
        }

        header: MessageViewHeader {
            id: messageHeader

            width: view.width
            email: view.email

            contentX: landscapeInviteContainer.width

            isOutgoing: view.isOutgoing
            attachmentsModel: view.attachmentsModel
            showLoadImages: view.showImagesButton
            heightBehaviorEnabled: view.complete && !view.orientationTransitionRunning

            onClicked: pageStack.navigateForward()

            onLoadImagesClicked: {
                if (showLoadImages) {
                    view.showImagesButton = false
                    WebEngineSettings.autoLoadImages = true
                    flickable.webView.reload()
                }
            }

            onLoadImagesCloseClicked: {
                view.showImagesButton = false
            }

            Loader {
                id: inviteLoader

                parent: view.portrait ? messageHeader.contentItem : landscapeInviteContainer

                active: messageHeader.inlineInvitation

                sourceComponent: CalendarInvite {
                    width: view.portrait ? view.width : Theme.buttonWidthLarge
                    height: view.portrait ? undefined : view.height - messageHeader.contentY

                    preferredButtonWidth: view.portrait
                            ? Theme.buttonWidthExtraSmall
                            : Theme.buttonWidthSmall

                    event: messageHeader.event
                    occurrence: messageHeader.occurrence
                }
            }
        }

        VerticalScrollDecorator { color: Theme.highlightBackgroundColor }
        HorizontalScrollDecorator { color: Theme.highlightBackgroundColor }

        Column {
            id: landscapeInviteContainer

            y: flickable.webView.y
        }

        Rectangle {
            x: landscapeInviteContainer.x
            y: flickable.webView.y
            z: -100
            width: view.width - x
            height: view.height - y

            color: flickable.webView.backgroundColor
            visible: widthChangeAnimation.running
        }

        Rectangle {
            id: resizeWhiteout

            x: landscapeInviteContainer.width
            y: flickable.webView.y
            width: view.width - x
            height: flickable.webView.height

            color: flickable.webView.backgroundColor

            opacity: 0
        }

        LinkHandler {
            id: linkHandler
        }

        MessageViewFooter {
            id: footer

            x: landscapeInviteContainer.width
            y: flickable.contentHeight - flickable.webView.footerMargin
            portrait: view.portrait

            width: view.width - x

            textSelectionController: flickable.webView.textSelectionController
            showReplyAll: view.email.multipleRecipients

            open: true

            onOpenChanged: {
                if (flickable.webView.chrome !== open) {
                    flickable.webView.chrome = open
                }
            }

            onForward: view.composerRequested('forward')
            onReplyAll: view.composerRequested('replyAll')
            onReply: view.composerRequested('reply')
            onDeleteEmail: {
                pageStack.pop()
                view.removeRequested()
            }
        }
    }
}
