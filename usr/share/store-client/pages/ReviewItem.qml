import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0

ListItem {
    id: reviewItem

    property string uuid
    property string appUuid
    property string authorName
    property alias review: reviewLabel.plainText
    property string version
    property date createdOn
    property date updatedOn
    property bool isAppAuthor
    property bool isSelf
    property string packageVersion
    property int horizontalMargin: Theme.horizontalPageMargin

    contentHeight: reviewLabel.height + authorLabel.height + 2 * Theme.paddingMedium
    enabled: isSelf && uuid.length > 0
    menu: Component {
        ContextMenu {
            MenuItem {
                //% "Delete"
                text: qsTrId("jolla-store-me-delete_comment")
                onClicked: {
                    remorseDelete(removeTimer.start)
                }
            }
        }
    }

    Timer {
        // Need to use a timer for removing the item because
        // the remorse item gets upset if the item is deleted
        // synchronously in the remorse callback function.
        id: removeTimer
        interval: 1
        onTriggered: {
            // Removed by sending an empty comment
            // (server.cpp handles the special case)
            jollaStore.sendReview(uuid, appUuid, "", packageVersion)
        }
    }

    onClicked: {
        var props = {
            "uuid": uuid,
            "appUuid": appUuid,
            "packageVersion": packageVersion,
            "text": review
        }
        pageStack.animatorPush(Qt.resolvedUrl("ReviewEditorPage.qml"), props)
    }

    LinkedText {
        id: reviewLabel
        anchors {
            top: parent.top
            topMargin: Theme.paddingMedium
            left: parent.left
            right: parent.right
            leftMargin: horizontalMargin
            rightMargin: horizontalMargin
        }
        font.pixelSize: Theme.fontSizeSmall
        color: (isSelf && !reviewItem.pressed) ? Theme.primaryColor : Theme.highlightColor
        linkColor: isSelf || reviewItem.pressed ? Theme.highlightColor : Theme.primaryColor
    }

    Image {
        id: authorIcon
        anchors {
            verticalCenter: authorLabel.verticalCenter
            left: reviewLabel.left
        }

        source: isSelf ? ("image://theme/icon-s-edit?" + (reviewItem.pressed ? Theme.highlightColor
                                                                             : Theme.primaryColor))
                       : isAppAuthor ? "image://theme/icon-s-developer" : ""
    }

    Label {
        id: authorLabel
        anchors {
            top: reviewLabel.bottom
            left: authorIcon.source != "" ? authorIcon.right : reviewLabel.left
            leftMargin: authorIcon.source != "" ? Theme.paddingMedium : 0
            right: reviewLabel.right
        }
        font.pixelSize: Theme.fontSizeExtraSmall
        truncationMode: TruncationMode.Fade
        color: reviewItem.pressed
               ? Theme.secondaryHighlightColor
               : Theme.secondaryColor
        text: {
            var txt = authorName + " • " + reviewItem.version + " • "
            var timestamp = Format.formatDate(reviewItem.updatedOn,
                                              Formatter.TimeElapsed)
            if (reviewItem.updatedOn > reviewItem.createdOn) {
                //: Timestamp label for edited comments. Takes the timestamp as a
                //: parameter (in format 'N minutes/hours/days ago').
                //: Notice that the timestamp localization expects that it's in the
                //: beginning of a sentence, thus a colon is needed after "Edited".
                //% "Edited: %1"
                txt += qsTrId("jolla-store-la-edited_time").arg(timestamp)
            } else {
                txt += timestamp
            }
            return txt
        }
    }
}
