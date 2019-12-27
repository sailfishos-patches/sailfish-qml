/*
 * Copyright (c) 2017 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.email 1.1

Page {
    id: composerPage

    property alias attachmentsModel: composer.attachmentsModel
    property alias emailSubject: composer.emailSubject
    property alias emailTo: composer.emailTo
    property alias emailCc: composer.emailCc
    property alias emailBcc: composer.emailBcc
    property alias emailBody: composer.emailBody
    property alias messageId: composer.messageId

    property alias action: composer.action
    property alias originalMessageId: composer.originalMessageId
    property alias accountId: composer.accountId

    property alias popDestination: composer.popDestination
    property alias draft: composer.draft
    property var draftRemoveCallback

    // Lazy load cover
    onStatusChanged: {
        if (status === PageStatus.Active) {
            app.coverMode = "mailEditor"
            // Check if all content is available for FWD
            if (composer.action === 'forward' && !composer.discardUndownloadedAttachments) {
                composer.forwardContentAvailable()
            }
        }
    }

    Connections {
        target: app
        onMovingToMainPage: {
            if (composer.messageContentModified()) {
                composer.saveDraft()
            }
        }
    }

    Binding {
        target: app
        property: "editorTo"
        value: composer._toSummary
    }

    Binding {
        target: app
        property: "editorBody"
        value: composer._bodyText
    }

    EmailComposer {
        id: composer

        autoSaveDraft: true
        onRequestDraftRemoval: {
            if (composerPage.draftRemoveCallback) {
                composerPage.draftRemoveCallback()
            }
        }
    }
}
