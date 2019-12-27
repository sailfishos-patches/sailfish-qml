import QtQuick 2.0
import Sailfish.Messages 1.0
import org.nemomobile.commhistory 1.0

QtObject {
    id: root

    property string localUid
    property var remoteUids: [ ]

    property var channels: [ ]
    property int groupId: -1

    property bool broadcast: channels.length > 1
    property bool hasChannel: channels.length > 0
    readonly property bool isSMS: MessageUtils.isSMS(localUid)

    property MmsHelper _mmsHelper: MmsHelper { }
    property bool _sendInProgress

    signal messageSent(int eventId)
    signal messageBroadcast(int eventId)

    function clear() {
        localUid = ""
        remoteUids = [ ]
        channels = [ ]
        groupId = -1
    }

    function matchChannel(local, remotes) {
        if (remoteUids.length !== remotes.length) {
            return false
        }
        for (var i = 0; i < remoteUids.length; ++i) {
            if (!groupManager.uidPairsMatch(local, remotes[i], localUid, remoteUids[i])) {
                return false
            }
        }
        return true
    }

    function setChannel(local, remote, group) {
        if (remoteUids.length == 1 &&
            groupManager.uidPairsMatch(local, remote, localUid, remoteUids[0])) {
            return 
        }

        remoteUids = [ remote ]
        groupId = (group === undefined) ? -1 : group
        updateChannel(local)
    }

    function updateChannel(local) {
        if (MessageUtils.isSMS(local)) {
            localUid = Qt.binding(function() { return MessageUtils.telepathyAccounts.ringAccountPath })
        } else {
            localUid = local
        }

        if (remoteUids.length > 0) {
            var channel = channelManager.getConversation(localUid, remoteUids[0])
            if (channel === null) {
                console.log("createChannel failed: ", localUid, remoteUids[0], "\n")
                return
            }
            channel.sendingFailed.disconnect(_sendingFailed)
            channel.sendingFailed.connect(_sendingFailed)

            channel.sendingSucceeded.disconnect(_sendingSucceeded)
            channel.sendingSucceeded.connect(_sendingSucceeded)

            channels = [ channel ]
        }
    }

    function setBroadcastChannel(local, remotes, group) {
        localUid = local
        remoteUids = remotes
        groupId = (group === undefined) ? -1 : group

        var c = [ ]
        for (var i = 0; i < remoteUids.length; i++) {
            var channel = channelManager.getConversation(localUid, remoteUids[i])
            channel.sendingFailed.disconnect(_sendingFailed)
            channel.sendingFailed.connect(_sendingFailed)

            channel.sendingSucceeded.disconnect(_sendingSucceeded)
            channel.sendingSucceeded.connect(_sendingSucceeded)

            c.push(channel)
        }

        channels = c
    }

    function sendMessage(text) {
        // JS-scope variables are accessible from inside callbacks, but the QML ID scope may be inaccessible...
        var messageChannel = root
        messageChannel._sendInProgress = true
        if (broadcast) {
            groupManager.createOutgoingMessageEvent(groupId, localUid, remoteUids, text, function(broadcastEventId) {
                var n = channels.length
                for (var i = 0; i < channels.length; i++) {
                    // Create a function to scope the 'channel' variable for each instance:
                    var fn = function() {
                        var channel = channels[i]

                        // Create the outgoing message event. An appropriate group will be found or created.
                        groupManager.createOutgoingMessageEvent(-1, channel.localUid, channel.remoteUid, text, function(eventId) {
                            channel.sendMessage(text, eventId)

                            --n
                            if (n == 0) {
                                groupManager.setEventStatus(broadcastEventId, CommHistory.SentStatus)
                                messageChannel.messageBroadcast(broadcastEventId)
                                messageChannel._sendInProgress = false
                            }
                        })
                    }()
                }
            })
        } else {
            groupManager.createOutgoingMessageEvent(groupId, localUid, remoteUids[0], text, function(eventId) {
                channels[0].sendMessage(text, eventId)
                messageChannel._sendInProgress = false
            })
        }
    }

    // event should be an object with properties similar to those from EventModel
    function retryEvent(event) {
        if (event.eventId < 0)
            return

        if (event.eventType === CommHistory.MMSEvent) {
            if (event.direction === CommHistory.Inbound) {
                _mmsHelper.receiveMessage(event.eventId)
            } else {
                _mmsHelper.retrySendMessage(event.eventId)
            }
        } else if (event.direction === CommHistory.Outbound) {
            if (event.localUid != "" && event.remoteUid != "")
                setChannel(event.localUid, event.remoteUid)

            for (var i = 0; i < channels.length; i++) {
                // Only retry the send with the same localUid, otherwise we may be breaking
                // the user's deliberate separation between target UID and local account
                if (channels[i].localUid == event.localUid &&
                    groupManager.uidPairsMatch(event.localUid, event.remoteUid, channels[i].localUid, channels[i].remoteUid)) {
                    channels[i].sendMessage(event.freeText, event.eventId)
                    break
                }
            }
        }
    }

    function cancelEvent(event) {
        if (event.eventId < 0)
            return

        if (event.eventType === CommHistory.MMSEvent) {
            _mmsHelper.cancel(event.eventId)
        }
    }

    function eventIsPending(local, remote, eventId) {
        // We don't want to instantiate a channel to make this check so the event must match one
        // of our already active channels
        if (localUid == local) {
            for (var i = 0; i < remoteUids.length; i++) {
                if (remoteUids[i] == remote) {
                    if (_sendInProgress) {
                        // If we haven't completed the send operation yet, we can't be certain that the event
                        // has made it to the pending set, since that happens asynchronously with the
                        // notification of event addition reaching the list view
                        return true
                    }

                    var channel = channelManager.getConversation(local, remote)
                    // Return whether the event is pending, but first establish a dependency on the
                    // sequence number so that we re-evaluate if the channel's pending set changes
                    return channel.sequence, channel.eventIsPending(eventId)
                }
            }
        }

        return false
    }

    function _sendingFailed(eventId, sender) {
        groupManager.setEventStatus(eventId, CommHistory.TemporarilyFailedStatus)
    }

    function _sendingSucceeded(eventId, sender) {
        root.messageSent(eventId)
    }
}

