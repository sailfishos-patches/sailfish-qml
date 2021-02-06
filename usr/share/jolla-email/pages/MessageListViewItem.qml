/*
 * Copyright (c) 2014 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1

MessageItem {
    // About to be deleted
    onEmailViewerRequested: {
        pageStack.animatorPush(app.getMessageViewerComponent(), {
                                   "messageId": messageId,
                                   "isOutgoing": isOutgoingFolder,
                                   "removeCallback": function(id) { remove() }
                               })
    }
}
