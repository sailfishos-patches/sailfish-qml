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
            //% "Share"
            acceptText: qsTrId("twittershare-he-share_heading")
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
            width: root.width - Theme.paddingLarge*2
            text: root.content.status
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 3
            font.pixelSize: Theme.fontSizeSmall
        }
    }

    TextArea {
        id: textField
        visible: root.isLink
        width: parent.width
        anchors.bottom: parent.bottom
        //: Label indicating text area is used for entering tweet.
        //% "Tweet"
        label: qsTrId("twittershare-la-description") + " (" + textField.text.length + ")"
        //: Placeholder text for tweet text area
        //% "My tweet"
        placeholderText: qsTrId("twittershare-ph-description")
    }

    SailfishShare {
        id: shareItem
        source: root.source
        serviceId: root.methodId
        userData: root.isLink ? {
                     "accountId": root.accountId,
                     "status": textField.text !== "" ? textField.text + " " + root.content.status
                                                     : root.content.status
                 } : {
                     "accountId": root.accountId,
                     "status": root.content.status
                 }
        mimeType: "text/plain" //This is either url or status which basically are the same for Twitter
    }

    Component.onCompleted: textField.forceActiveFocus()
}
