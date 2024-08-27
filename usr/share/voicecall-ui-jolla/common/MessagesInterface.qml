import Nemo.DBus 2.0

DBusInterface {
    service: "org.sailfishos.Messages"
    path: "/"
    iface: "org.sailfishos.Messages"

    function startSMS(phoneNumber) {
        typedCall('startSMS', [
            { 'type':'s', 'value': phoneNumber }
        ])
    }
}
