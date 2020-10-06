/*
 * Copyright (c) 2012 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import Sailfish.WebView 1.0
import org.nemomobile.configuration 1.0

WebViewPage {
    id: messageViewPage

    property alias messageId: message.messageId
    property Page messageInfoPage
    property bool loaded
    property bool isOutgoing
    readonly property bool replyAll: message.multipleRecipients
    property Page previousPage: pageStack.previousPage()
    // either undefined or function taking message id as parameter
    property var removeCallback
    property string pathToLoad
    readonly property bool isLocalFile: pathToLoad !== ""
    readonly property string _mimeType: message.contentType == EmailMessage.HTML
            ? "text/html"
            : "text/plain"

    property bool _sendReadReceipt

    function doRemove() {
        if (removeCallback) {
            removeCallback(messageId)
        } else {
            console.warn("MessageView requested removal, but there is no handler defined")
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Activating && isLocalFile) {
            message.loadFromFile(pathToLoad);
        }
        if (status == PageStatus.Active) {
            if (!loaded) {
                htmlLoader.load(message.htmlBody, _mimeType, message)
            }
            pageStack.pushAttached(messageInfoComponent, { message: message })
            app.coverMode = "mailViewer"
        }
    }

    Component.onDestruction: {
        if (_sendReadReceipt) {
            switch (sendReadReceiptsConfig.value) {
            case 0:
                pageStack.animatorPush(Qt.resolvedUrl("SendReadReceiptDialog.qml"), { originalEmailId: messageId })
                break
            case 1: // always send
                if (!message.sendReadReceipt(
                            // Defined in SendReadReceiptDialog
                            qsTrId("jolla-email-la-read_receipt_email_subject_prefix"),
                            // Defined in SendReadReceiptDialog
                            qsTrId("jolla-email-la-read_receipt_email_body")
                            .arg(Qt.formatTime(originalEmail.date))
                            .arg(Qt.formatDate(originalEmail.date))
                            .arg(message.accountAddress))) {
                    // Defined in SendReadReceiptDialog
                    app.showSingleLineNotification(qsTrId("jolla-email-la-failed_send_read_receipt"))
                }
                break
            default:
                break
            }
        }
    }

    EmailMessage {
        id: message
        autoVerifySignature: autoVerifySignatureConfig.value

        onHtmlBodyChanged: {
            if (messageViewPage.status == PageStatus.Active) {
                // Some messages where minimal data is retrieved(preview)
                // will be of type plain until next parts are available
                if (!htmlLoader.visible) {
                    loaded = false
                    plainTextViewer.active = false
                    htmlLoader.visible = true
                }
                htmlLoader.load(htmlBody, messageViewPage._mimeType, message)
            }
        }

        onBodyChanged: {
            if (loaded && (contentType == EmailMessage.Plain)) {
                plainTextViewer.active = true
                plainTextViewer.loadBody()
            }
        }

        onInlinePartsDownloaded: {
            // Some servers(e.g exchange), always update all message properties
            // when some parts are retrived, the server as priority, so for the case of
            // inline images the message read state can change back to unread
            htmlLoader.markAsRead()
        }
    }

    HtmlLoader {
        id: htmlLoader

        anchors.fill: parent
        portrait: messageViewPage.isPortrait
        attachmentsModel: attachModel
        isOutgoing: messageViewPage.isOutgoing
        isLocalFile: messageViewPage.isLocalFile
        onRemoveRequested: messageViewPage.doRemove()
        onNeedToSendReadReceipt: {
            _sendReadReceipt = true
        }
    }

    Component {
        id: messageInfoComponent
        MessageInfo {
            isLocalFile: messageViewPage.isLocalFile
        }
    }

    AttachmentListModel {
        id: attachModel
        messageId: message.messageId
    }

    Binding {
        target: app
        property: "viewerSender"
        value: message.fromDisplayName
    }

    Binding {
        target: app
        property: "viewerSubject"
        value: message.subject
    }

    ConfigurationValue {
        id: sendReadReceiptsConfig
        key: "/apps/jolla-email/settings/sendReadReceipts"
        defaultValue: 0
    }

    ConfigurationValue {
        id: autoVerifySignatureConfig
        key: "/apps/jolla-email/settings/autoVerifySignature"
        defaultValue: false
    }
}
