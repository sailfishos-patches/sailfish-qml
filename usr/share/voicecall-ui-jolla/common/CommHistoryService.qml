import QtQuick 2.0
import Nemo.DBus 2.0

DBusInterface {
    id: service
    service: "org.nemomobile.CommHistory"
    path: "/org/nemomobile/CommHistory"
    iface: "org.nemomobile.CommHistoryIf"

    property bool callHistoryObserved

    onCallHistoryObservedChanged: {
        service.call("setCallHistoryObserved", callHistoryObserved)
    }
}
