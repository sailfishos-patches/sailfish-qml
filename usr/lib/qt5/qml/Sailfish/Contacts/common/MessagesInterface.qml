import Nemo.DBus 2.0

DBusInterface {
    service: "org.sailfishos.Messages"
    path: "/"
    iface: "org.sailfishos.Messages"

    function startConversation(localUid, remoteUid) {
        typedCall('startConversation', [
            { 'type':'s', 'value':localUid },
            { 'type':'s', 'value':remoteUid }
        ])
    }

    function startSMS(phoneNumber) {
        typedCall('startSMS', [
            { 'type':'s', 'value':phoneNumber }
        ])
    }
}

