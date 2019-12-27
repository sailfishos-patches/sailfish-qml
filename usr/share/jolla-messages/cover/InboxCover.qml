import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.commhistory 1.0

Column {
    id: inboxCover

    ConversationDelegate {
        id: dummy
        extraSmall: true
        visible: false
        width: parent.width
        messageText: "Message"
        recipients: "Recipient"
        readonly property bool valid: messageItem.height > 0
    }

    property int maximumGroupsCount: dummy.valid ? Math.ceil((height - y + spacing) / (dummy.height + spacing)) : 0
    onMaximumGroupsCountChanged: if (maximumGroupsCount > 0) conversations.updateGroups()

    width: parent ? parent.width : 0
    y: Theme.paddingMedium
    spacing: Theme.paddingMedium - 1

    Connections {
        target: groupModel
        onCountChanged: conversations.updateGroups()
        onRowsMoved: conversations.updateGroups()
    }

    Repeater {
        id: conversations

        property var groups: new Array

        function updateGroups() {
            if (maximumGroupsCount === 0) return

            var list = []
            var i
            for (i = 0; i < groupModel.count && i < maximumGroupsCount; ++i) {
                list.push(groupModel.at(i))
            }
            if (list.length != groups.length) {
                groups = list
            } else if (list.length) {
                for (i = 0; i < list.length; ++i) {
                    if (groups[i] != list[i]) {
                        groups = list
                        break
                    }
                }
            }
        }

        model: groups

        delegate: ConversationDelegate {
            readonly property int maximumLines: Math.max(0, Math.ceil((inboxCover.height - y - dummy.recipientsItem.height) / dummy.lineHeight))
            readonly property real bottomY: y + height

            width: parent ? parent.width : 0
            messageText: mainWindow.groupMessageText(modelData)
            recipients: mainWindow.groupRecipients(modelData)
            visible: maximumLineCount > 0

            maximumLineCount: Math.min(3, maximumLines)
            extraSmall: true
            needsFading: maximumLineCount > 0 && bottomY > inboxCover.height
        }
    }
}
