import QtQuick 2.0
import QOfono 0.2

OfonoCellBroadcast {
    id: cellBroadcast

    property var dialog

    function showCellBroadcastMessage(text, properties) {
        console.log(text)
        if (!dialog) {
            var component = Qt.createComponent("CellBroadcastMessage.qml")
            if (component.status === Component.Ready) {
                dialog = component.createObject(cellBroadcast)
            } else {
                console.log(component.errorString())
            }
        }
        if (dialog) {
            dialog.text = text
            dialog.properties = properties
            dialog.activate()
        }
    }

    onIncomingBroadcast: showCellBroadcastMessage(text, {"Topic": topic})

    onEmergencyBroadcast: showCellBroadcastMessage(text, properties)
}
