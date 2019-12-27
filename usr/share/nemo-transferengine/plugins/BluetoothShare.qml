import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TransferEngine 1.0
import Sailfish.Bluetooth 1.0

BluetoothDevicePickerDialog {
    id: root

    property url source
    property variant content: ({})
    property string methodId
    property string displayName
    property int accountId
    property string accountName
    property alias shareEndDestination: root.acceptDestination

    acceptDestinationAction: PageStackAction.Pop
    preferredProfileHint: BluetoothProfiles.ObexObjectPush

    onAccepted: {
        shareItem.start()
    }

    SailfishShare {
        id: shareItem
        source: root.source
        content: root.content
        serviceId: root.methodId
        userData: {"deviceAddress": root.selectedDevice}
    }
}
