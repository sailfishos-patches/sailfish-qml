import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    property string testName: "coverpage"
    property int topMargin: Theme.itemSizeSmall
    property int itemCount: Math.round((parent.height-Theme.itemSizeSmall)/label.lineHeight)

    Repeater {
        model: itemCount
        delegate: Rectangle {
            y: topMargin + index * label.lineHeight
            width: parent.width
            // gives 1.5 on phone, which looks OK on the phone small cover.
            height: Theme.paddingSmall/4
            color: Theme.primaryColor
            opacity: Theme.opacityLow
        }
    }

    Label {
        id: label
        property var noteText: {
            if (pageStack.depth > 1 && currentNotePage) {
                return currentNotePage.text.trim()
            } else if (notesModel.count > 0 && notesModel.moveCount) {
                return notesModel.get(0).text.trim()
            }

            return undefined
        }
        text: noteText !== undefined
              ? noteText.replace(/\n/g, " ")
              // From notes.cpp
              : qsTrId("notes-de-name")
        x: Theme.paddingSmall/2
        y: topMargin - baselineOffset - Theme.paddingSmall + (noteText !== undefined ? 0 : lineHeight)
        opacity: Theme.opacityHigh
        font.pixelSize: Theme.fontSizeExtraLarge
        font.italic: true
        width: noteText !== undefined ? parent.width + Theme.itemSizeLarge : parent.width - Theme.paddingSmall
        horizontalAlignment: noteText !== undefined || implicitWidth > width - Theme.paddingSmall ? Text.AlignLeft : Text.AlignHCenter
        lineHeightMode: Text.FixedHeight
        lineHeight: Math.floor(Theme.fontSizeExtraLarge * 1.35)
        wrapMode: noteText !== undefined ? Text.Wrap : Text.NoWrap
        maximumLineCount: itemCount
    }

    CoverActionList {
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: {
                openNewNote(PageStackAction.Immediate)
                activate()
            }
        }
    }
}
