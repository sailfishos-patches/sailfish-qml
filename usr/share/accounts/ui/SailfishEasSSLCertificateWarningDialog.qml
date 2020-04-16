import QtQuick 2.6
import Sailfish.Silica 1.0

Dialog {
    Column {
        width: parent.width
        spacing: Theme.paddingLarge

        DialogHeader {
            //: Header text
            //% "Delete"
            acceptText: qsTrId("components_accounts-ph-activesync_certificate_delete")
        }

        Image {
            source: "image://theme/icon-l-attention"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            width: parent.width - 2*x
            x: Theme.horizontalPageMargin
            //% "Are you sure you want to delete the imported client certificate?"
            text: qsTrId("components_accounts-lb-extraction_delete_warning")
            font.pixelSize: Theme.fontSizeExtraLarge
            color: Theme.highlightColor
            wrapMode: TextEdit.WordWrap
        }

        Label {
            width: parent.width - 2*x
            x: Theme.horizontalPageMargin
            //% "This action is permanent, you will not be able to undo it."
            text: qsTrId("components_accounts-lb-extraction_warning")
            color: Theme.highlightColor
            wrapMode: TextEdit.WordWrap
        }
    }
}
