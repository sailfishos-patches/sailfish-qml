import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.commhistory 1.0

Item {
    id: messageCover

    property string messageText: {
        if (mainWindow.editorActive) {
            return mainWindow.draftText
        }
        return mainWindow.groupMessageText(mainWindow.conversationGroup)
    }

    property string recipients: {
        if (mainWindow.conversationRecipients) {
            return mainWindow.conversationRecipients
        }
        if (mainWindow.editorActive) {
            //: cover text on message editor mode, <br/> can be used for line feed
            //% "NEW<br/>MESSAGE"
            var text = qsTrId("jolla-messages-new_message_cover")
            return text.replace("<br/>", "\n")
        }
        return ''
    }

    anchors.fill: parent

    ConversationDelegate {
        id: conversation
        y: parent.height - height - Theme.paddingMedium
        width: parent.width
        messageText: messageCover.messageText
        recipients: messageCover.recipients
        maximumLineCount: (parent.height - Theme.paddingMedium - recipientsItem.height)/lineHeight
    }

    Column {
        id: dummyTextIndicator

        width: parent.width
        y: conversation.y - height

        Repeater {
            visible: mainWindow.editorActive && messageText == ''
            model: visible ? [ 0.9, 1, 0.8, 0.65 ] : []

            delegate: Item {
                x: Theme.paddingMedium
                width: parent ? parent.width - 2*x : 0
                height: messageCover.height / 10

                Rectangle {
                    width: parent.width * modelData
                    y: 1
                    height: parent.height - y
                    radius: Theme.paddingSmall/2
                    color: 'white'
                }
            }
        }
    }
}
 
