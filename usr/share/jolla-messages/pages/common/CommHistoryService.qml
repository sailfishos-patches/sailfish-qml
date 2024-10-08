import QtQuick 2.0
import Nemo.DBus 2.0

DBusInterface {
    id: service
    service: "org.nemomobile.CommHistory"
    path: "/org/nemomobile/CommHistory"
    iface: "org.nemomobile.CommHistoryIf"

    property var observedGroups
    property bool inboxObserved

    onObservedGroupsChanged: {
        var value = [ ]
        for (var i = 0; i < observedGroups.length; i++) {
            // List of groups, which are a list of localUid, remoteUid, type (0 for ChatTypeP2P)
            value[value.length] = [ observedGroups[i].localUid, observedGroups[i].remoteUids[0], 0 ]
        }
        service.call("setObservedConversations", [ value ])
    }

    onInboxObservedChanged: {
        service.call("setInboxObserved", inboxObserved)
    }
}

