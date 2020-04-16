import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TransferEngine 1.0

ShareFilePreviewDialog {
    id: root

    shareItem.metadataStripped: true

    //: Placeholder text for tweet text area
    //% "My tweet"
    descriptionPlaceholderText: qsTrId("twittershare-ph-description")

    onAccepted: {
        shareItem.start()
    }
}
