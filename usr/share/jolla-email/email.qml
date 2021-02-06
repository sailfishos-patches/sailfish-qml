/*
 * Copyright (c) 2012 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.WebEngine 1.0
import Nemo.Email 0.1
import org.nemomobile.notifications 1.0
import com.jolla.email 1.1
import com.jolla.settings.accounts 1.0
import com.jolla.signonuiservice 1.0
import org.nemomobile.time 1.0
import Nemo.Connectivity 1.0
import "pages"
import "pages/utils.js" as Utils

ApplicationWindow {
    id: app

    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    property alias numberOfAccounts: mailAccountListModel.numberOfAccounts
    property alias syncInProgress: emailAgent.synchronizing
    property bool refreshSyncTime
    readonly property string lastAccountUpdate: {
        // Cheating a bit as needsUpdate is always true but property changes are
        // of our interest here.
        var needsUpdate = Qt.application.active || refreshSyncTime || true
        if (mailAccountListModel.persistentConnectionActive) {
            return qsTrId("email-la_up_to_date")
        } else if (needsUpdate) {
            return Utils.lastSyncTime(mailAccountListModel.lastUpdateTime)
        }
    }
    property bool accountsManagerActive
    readonly property int defaultMessageListLimit: 100

    // State for cover
    property string coverMode: "mainView"
    property bool errorOccurred
    property string lastErrorText
    property string viewerSender
    property string viewerSubject
    property string editorTo
    property string editorBody
    property int inboxUnreadCount
    property int combinedInboxUnreadCount

    property Page _mainPage
    property Component _messageViewerComponent
    property bool _hasCombinedInbox
    property var today: new Date()

    signal movingToMainPage()

    cover: Qt.resolvedUrl("cover/EmailCover.qml")

    Component.onCompleted: {
        _updateMainPage()
    }

    WallClock {
        id: wallClock

        enabled: Qt.application.state === Qt.ApplicationActive
        updateFrequency: WallClock.Minute

        onTimeChanged: {
            var now = wallClock.time
            if (now.getDate() !== app.today.getDate()
                    || now.getMonth() !== app.today.getMonth()
                    || now.getYear() !== app.today.getYear()) {
                app.today = now
            }
        }
    }

    Connections {
        target: EmailService

        onShowCompose: {
            _navigateToMainPage()
            if (app.numberOfAccounts) {
                var obj = pageStack.animatorPush(Qt.resolvedUrl("pages/ComposerPage.qml"), {
                                                     emailTo: emailTo,
                                                     emailSubject: emailSubject,
                                                     emailCc: emailCc,
                                                     emailBcc: emailBcc,
                                                     emailBody: emailBody},
                                                 PageStackAction.Immediate)
                obj.pageCompleted.connect(function(page) {
                    for (var attachment in attachments) {
                        page.attachmentsModel.append({
                                                         "url": attachments[attachment]["url"],
                                                         "title": attachments[attachment]["name"],
                                                         "mimeType": attachments[attachment]["mime"],
                                                         "FromOriginalMessage": "false"
                                                     })
                    }
                })
            }
            app.activate()
        }

        onShowCombinedInbox: {
            _navigateToMainPage()
            app.activate()
        }

        onShowInbox: {
            _navigateToAccountInbox(accountId)
            app.activate()
        }

        onShowMessage: {
            if (emailAgent.isMessageValid(messageId)) {
                _navigateToAccountInbox(emailAgent.accountIdForMessage(messageId))
                pageStack.animatorPush(app.getMessageViewerComponent(),
                                       {
                                           "messageId": messageId,
                                           "removeCallback": pageStack.currentPage.removeMessage,
                                           "messageAction": messageAction,
                                       },
                                       PageStackAction.Immediate)
            } else {
                _navigateToMainPage()
                console.log("Message is not valid:", messageId)
            }
            app.activate()
        }

        onShowWindow: app.activate()
    }

    function _navigateToMainPage() {
        movingToMainPage()
        if (pageStack.currentPage != _mainPage) {
            pageStack.pop(_mainPage, PageStackAction.Immediate)
        }
    }

    function _navigateToAccountInbox(accountId) {
        _navigateToMainPage()
        if (emailAgent.isAccountValid(accountId)) {
            pushAccountInbox(accountId, true)
        } else {
            console.log("Account is not valid:", accountId)
        }
    }

    function _updateMainPage() {
        if (numberOfAccounts === 0) {
            _navigateToMainPage()
            _mainPage = pageStack.replace(Qt.resolvedUrl("pages/NoAccountsPage.qml"), {}, PageStackAction.Immediate)
        } else if (numberOfAccounts === 1) {
            _navigateToMainPage()
            var accountId = mailAccountListModel.accountId(0)
            var inbox = emailAgent.inboxFolderId(accountId)

            if (inbox > 0) {
                var accessor = emailAgent.accessorFromFolderId(inbox)
                _mainPage = pageStack.replace(Qt.resolvedUrl("pages/MessageListPage.qml"), { folderAccessor: accessor },
                                              PageStackAction.Immediate)
            } else {
                _mainPage = pageStack.replace(Qt.resolvedUrl("pages/PendingInboxPage.qml"), { accountId: accountId },
                                              PageStackAction.Immediate)
                emailAgent.synchronizeInbox(accountId)
            }

            _hasCombinedInbox = false // remove this fellow
        } else if (!_hasCombinedInbox && numberOfAccounts > 1) {
            _navigateToMainPage()
            _mainPage = pageStack.replace(Qt.resolvedUrl("pages/CombinedInbox.qml"), {}, PageStackAction.Immediate)
            _hasCombinedInbox = true
        }
    }

    function pushAccountInbox(accountId, immediate) {
        var inbox = emailAgent.inboxFolderId(accountId)
        if (inbox > 0) {
            var accessor = emailAgent.accessorFromFolderId(inbox)
            pageStack.animatorPush(Qt.resolvedUrl("pages/MessageListPage.qml"), { folderAccessor: accessor },
                                   immediate ? PageStackAction.Immediate : PageStackAction.Animated)
        } else {
            pageStack.animatorPush(Qt.resolvedUrl("pages/PendingInboxPage.qml"), { accountId: accountId },
                                   immediate ? PageStackAction.Immediate : PageStackAction.Animated)
            emailAgent.synchronizeInbox(accountId)
        }
    }

    function showAccountsCreationDialog() {
        app.accountsManagerActive = true
        accountCreationLoader.setSource(pageStack.resolveImportPage("com.jolla.email.AccountCreation"), { endDestination: app._mainPage })
        accountCreationLoader.active = true
    }

    function getMessageViewerComponent() {
        if (componentCompiler.running) {
            componentCompiler.triggered()
        }

        return _messageViewerComponent
    }

    function showSingleLineNotification(text) {
        if (text.length > 0) {
            var n = notificationComponent.createObject(null, { 'summary': text,
                                                               'appIcon': "image://theme/icon-system-warning" })
            n.publish()
        }
    }

    Component {
        id: notificationComponent
        Notification {
            isTransient: true
        }
    }

    EmailAgent {
        id: emailAgent

        onSynchronizingChanged: {
            if (synchronizing) {
                errorOccurred = false
            }
        }

        onNetworkConnectionRequested: {
            connectionHelper.attemptToConnectNetwork()
        }

        // Global status used for the cover
        onError: {
            errorOccurred = true
            lastErrorText = Utils.syncErrorText(syncError)
        }

        onCalendarInvitationResponded: {
            if (!success) {
                var text = ""
                switch (response) {
                case EmailAgent.InvitationResponseAccept:
                    //: Failed to send invitation response (accept)
                    //% "Failed to accept invitation"
                    text = qsTrId("jolla-email-la-response_failed_body_accept")
                    break
                case EmailAgent.InvitationResponseTentative:
                    //: Failed to send invitation response (tentative)
                    //% "Failed to tentatively accept invitation"
                    text = qsTrId("jolla-email-la-response_failed_body_tentative")
                    break
                case EmailAgent.InvitationResponseDecline:
                    //: Failed to send invitation response (decline)
                    //% "Failed to decline invitation"
                    text = qsTrId("jolla-email-la-response_failed_body_decline")
                    break
                default:
                    break
                }
                showSingleLineNotification(text)
            }
        }

        onOnlineFolderActionCompleted: {
            if (!success) {
                var text = ""
                switch (action) {
                case EmailAgent.ActionOnlineCreateFolder:
                    //% "Folder creation failed"
                    text = qsTrId("jolla-email-la-fa_failed_body_create")
                    break
                case EmailAgent.ActionOnlineDeleteFolder:
                    //% "Folder deletion failed"
                    text = qsTrId("jolla-email-la-fa_failed_body_delete")
                    break
                case EmailAgent.ActionOnlineRenameFolder:
                    //% "Folder rename failed"
                    text = qsTrId("jolla-email-la-fa_failed_body_rename")
                    break
                case EmailAgent.ActionOnlineMoveFolder:
                    //% "Folder move failed"
                    text = qsTrId("jolla-email-la-fa_failed_body_move")
                    break
                default:
                    break
                }
                showSingleLineNotification(text)
            }
        }
    }

    EmailAccountListModel {
        id: mailAccountListModel

        onAccountsAdded: {
            // Don't try to modify pages while accounts configuration manager is running
            if (!accountsManagerActive) {
                _updateMainPage()
            }
        }
        onAccountsRemoved: {
            if (!accountsManagerActive) {
                _updateMainPage()
            }
        }
    }

    Timer {
        id: lastAccountUpdateRefreshTimer
        interval: 60000
        running: !syncInProgress
        repeat: true
        onTriggered: refreshSyncTime = !refreshSyncTime
    }

    ConnectionHelper {
        id: connectionHelper
    }

    Loader {
        id: accountCreationLoader
        active: false
        anchors.fill: parent

        Connections {
            target: accountCreationLoader.item
            ignoreUnknownSignals: true

            onCreationCompleted: {
                _updateMainPage()
                app.accountsManagerActive = false
                accountCreationLoader.active = false
            }
        }
    }

    Timer {
        // do some compilation ahead of time, but avoid delaying startup
        id: componentCompiler
        running: true
        interval: 500
        onTriggered: {
            running = false
            _messageViewerComponent = Qt.createComponent(Qt.resolvedUrl("pages/MessageView.qml"))
            Qt.createComponent(Qt.resolvedUrl("pages/ComposerPage.qml"), Component.Asynchronous)
        }
    }
}
