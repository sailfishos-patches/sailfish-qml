import QtQuick 2.6
import Sailfish.Silica 1.0
import "."

SecretsResetView {
    //: Appears when data corruption has been detected by the secrets daemon.
    //% "Data corruption detected. Please reset your secrets data. Affects your keys, collections, etc."
    text: qsTrId("secrets_ui-la-data_corruption_detected")
    header: PageHeader {
        //% "Keys"
        title: qsTrId("secrets_ui-he-keys")
    }
}
