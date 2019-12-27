import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TransferEngine 1.0

ShareDialog {
    id: root

    property bool isLink: root.content
                          && ('type') in root.content
                          && root.content.type === "text/x-url"

    onAccepted: {
        shareItem.start()
    }

    Column {
        width: parent.width
        y: height > textField.y ? textField.y - height : 0
        spacing: Theme.paddingSmall

        DialogHeader {
            id: header
            //: Share to VK dialog header
            //% "Share"
            acceptText: qsTrId("vkshare-he-share_heading")
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.isLink
            text: root.content.linkTitle
            width: root.width - Theme.paddingLarge*2
            elide: Text.ElideRight
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.secondaryHighlightColor
            text: root.content.status
            width: root.width - Theme.paddingLarge*2
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 3
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    TextArea {
        id: textField
        visible: root.isLink
        //: Label indicating text field is used for entering vk status
        //% "Status"
        label: qsTrId("vkshare-la-status")
        //: Placeholder text for VK status text area
        //% "My status"
        placeholderText: qsTrId("vkshare-ph-my_status")
        width: parent.width
        anchors.bottom: parent.bottom
    }

    SailfishShare {
        id: shareItem
        source: root.source
        serviceId: root.methodId
        userData: root.isLink ? {
                    "accountId": root.accountId,
                    "link": root.content.status,
                    "status": textField.text
                  } : {
                    "accountId": root.accountId,
                    "status": root.content.status
                  }
        mimeType: root.isLink ? "text/x-url" : "text/plain"
    }

    Component.onCompleted: textField.forceActiveFocus()
}
