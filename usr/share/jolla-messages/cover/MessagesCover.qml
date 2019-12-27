import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Messages 1.0

CoverBackground {
    id: root

    property string coverType: mainWindow.conversationGroup || mainWindow.editorActive ? "single" : (groupModel.count > 0 ? "inbox" : "")

    property bool showAction: coverType != "single"
    property bool smallCover: size == Cover.Small
    property real scaleFactor: height / Theme.coverSizeLarge.height
    property real scaledHeight: height / scaleFactor
    property real scaledWidth: width / scaleFactor
    property real actionHeight: coverActionArea.height / scaleFactor

    allowResize: true

    Item {
        id: scaling

        width: root.scaledWidth
        height: root.scaledHeight - (showAction ? root.actionHeight : 0)
        scale: smallCover ? root.scaleFactor : 1
        transformOrigin: Item.TopLeft

        Loader {
            id: coverSelector
            anchors.fill: parent

            sourceComponent: {
                if (coverType == "inbox") {
                    return inboxCoverComponent
                } else if (coverType == "single") {
                    return singleMessageCoverComponent
                } else {
                    return emptyStatePlaceHolderComponent
                }
            }

            Component {
                id: inboxCoverComponent
                InboxCover {}
            }
            Component {
                id: singleMessageCoverComponent
                SingleMessageCover {}
            }
            Component {
                id: emptyStatePlaceHolderComponent
                EmptyStatePlaceholder {
                    columnHeight: parent.height - Theme.paddingMedium
                }
            }
        }
    }

    CoverActionList {
        enabled: MessageUtils.hasModemOrIMaccounts && showAction

        CoverAction {
            iconSource: "image://theme/icon-cover-message"
            onTriggered: {
                mainWindow.activate()
                mainWindow.newMessage(PageStackAction.Immediate)
            }
        }
    }
}
