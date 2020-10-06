/*
 * Copyright (c) 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

.pragma library
.import Sailfish.Silica 1.0 as SS
.import Nemo.Email 0.1 as Email

var recentFolderSyncs = {}

function canSyncFolder(key, time) {
    // 30 second default folder sync interval.
    // Try to avoid too frequent syncs when switching between folders.
    var timeout = 30000

    var lastSync = recentFolderSyncs[key] || 0
    var elapsed = time - lastSync

    if (elapsed < timeout) {
        return false
    }

    return true
}

function updateRecentSync(key, value) {
    recentFolderSyncs[key] = value
}

function lastSyncTime(lastSynchronized) {
    if (lastSynchronized === 0) {
        return ""
    } else {
        var elapsedTime = SS.Format.formatDate(lastSynchronized, SS.Formatter.DurationElapsed)

        if (elapsedTime === "") {
            //: 'Up to date label'
            //% "Up to date"
            return qsTrId("email-la_up_to_date")
        } else {
            return elapsedTime
        }
    }
}

function priorityIcon(priority) {
    if (priority === Email.EmailMessageListModel.HighPriority) {
        return "image://theme/icon-s-high-importance"
    } else if (priority === Email.EmailMessageListModel.LowPriority) {
        return "image://theme/icon-s-low-importance"
    } else {
        return ""
    }
}

function standardFolderName(folderType, folderName) {
    if (folderType === Email.EmailFolder.InboxFolder) {
        //: Inbox folder
        //% "Inbox"
        return qsTrId("jolla-email-la-inbox_folder")
    } else if (folderType === Email.EmailFolder.OutboxFolder) {
        //: Outbox folder
        //% "Outbox"
        return qsTrId("jolla-email-la-outbox_folder")
    } else if (folderType === Email.EmailFolder.SentFolder) {
        //: Sent folder
        //% "Sent"
        return qsTrId("jolla-email-la-sent_folder")
    } else if (folderType === Email.EmailFolder.DraftsFolder) {
        //: Drafts folder
        //% "Drafts"
        return qsTrId("jolla-email-la-drafts_folder")
    } else if (folderType === Email.EmailFolder.TrashFolder) {
        //: Trash folder
        //% "Trash"
        return qsTrId("jolla-email-la-trash_folder")
    } else {
        return folderName
    }
}

function isLocalFolder(folderId) {
    return folderId === 1
}

function syncErrorText(syncError) {
    if (syncError === Email.EmailAgent.SyncFailed) {
        //: Synchronization failed error (Shown in app cover, small space)
        //% "Synchronization failed"
        return qsTrId("jolla-email-la-sync_failed")
    } else if (syncError === Email.EmailAgent.LoginFailed) {
        //: Login failed error (Shown in app cover, small space)
        //% "Login failed"
        return qsTrId("jolla-email-la-login_failed")
    } else if (syncError === Email.EmailAgent.DiskFull) {
        //: Disk full error (Shown in app cover, small space)
        //% "Disk Full"
        return qsTrId("jolla-email-la-disk_full")
    } else if (syncError === Email.EmailAgent.InvalidConfiguration) {
        //: Invalid configuration (Shown in app cover, small space)
        //% "Invalid configuration"
        return qsTrId("jolla-email-la-invalid_configuration")
    } else if (syncError === Email.EmailAgent.UntrustedCertificates) {
        //: Invalid certificate (Shown in app cover, small space)
        //% "Invalid certificate"
        return qsTrId("jolla-email-la-invalid_certificate")
    } else if (syncError === Email.EmailAgent.InternalError) {
        //: Internal error (Shown in app cover, small space)
        //% "Internal error"
        return qsTrId("jolla-email-la-internal_error")
    } else if (syncError === Email.EmailAgent.SendFailed) {
        //: Send failed (Shown in app cover, small space)
        //% "Send failed"
        return qsTrId("jolla-email-la-send_failed")
    } else if (syncError === Email.EmailAgent.Timeout) {
        //: Connection timeout (Shown in app cover, small space)
        //% "Connection timeout"
        return qsTrId("jolla-email-la-connection_timeout")
    } else if (syncError === Email.EmailAgent.ServerError) {
        //: Server error (Shown in app cover, small space)
        //% "Server error"
        return qsTrId("jolla-email-la-server_error")
    } else if (syncError === Email.EmailAgent.NotConnected) {
        //: Not connected (Shown in app cover, small space)
        //% "Not connected"
        return qsTrId("jolla-email-la-not_connected")
    }

    console.warn("Unknown error message")
    return ""
}

function sortTypeText(sortType) {
    if (sortType === Email.EmailMessageListModel.Time) {
        //: Sort by time
        //% "Time"
        return qsTrId("jolla-email-me-sort_time")
    } else if (sortType === Email.EmailMessageListModel.Sender) {
        //: sort by sender
        //% "Sender"
        return qsTrId("jolla-email-me-sort_sender")
    } else if (sortType === Email.EmailMessageListModel.Recipients) {
        //: sort by recipients
        //% "Recipients"
        return qsTrId("jolla-email-me-sort_recipients")
    } else if (sortType === Email.EmailMessageListModel.Size) {
        //: sort by size
        //% "Size"
        return qsTrId("jolla-email-me-sort_size")
    } else if (sortType === Email.EmailMessageListModel.ReadStatus) {
        //: sort by status
        //% "Status"
        return qsTrId("jolla-email-me-sort_status")
    } else if (sortType === Email.EmailMessageListModel.Priority) {
        //: sort by priority
        //% "Importance"
        return qsTrId("jolla-email-me-sort_importance")
    } else if (sortType === Email.EmailMessageListModel.Attachments) {
        //: sort by attachments
        //% "Attachments"
        return qsTrId("jolla-email-me-sort_attachments")
    } else if (sortType === Email.EmailMessageListModel.Subject) {
        //: sort by subject
        //% "Subject"
        return qsTrId("jolla-email-me-sort_subject")
    }

    console.warn("Unknown sort type")
    return ""
}

