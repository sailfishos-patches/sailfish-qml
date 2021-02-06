import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0

InverseMouseArea {
    property string uuid
    property string appUuid
    property string packageVersion
    property alias text: editor.text
    property int horizontalMargin: Theme.horizontalPageMargin

    signal reviewReady

    function forceActiveFocus() {
        editor.forceActiveFocus()
        editor.cursorPosition = editor.text.length
    }

    height: editor.height

    onClickedOutside: editor.focus = false

    TextArea {
        id: editor

        focusOutBehavior: FocusBehavior.KeepFocus
        textLeftMargin: horizontalMargin
        textRightMargin: horizontalMargin + sendButton.width + Theme.paddingMedium
        font.pixelSize: Theme.fontSizeSmall
        //: Placeholder text for the comment field
        //% "Your comment"
        placeholderText: qsTrId("jolla-store-ph-comment")
        label: placeholderText

        Button {
            id: sendButton
            parent: editor
            anchors {
                right: parent.right
                rightMargin: horizontalMargin
            }

            preferredWidth: Theme.buttonWidthTiny
            width: implicitWidth + 2*Theme.paddingMedium
            y: editor.contentItem.y + editor.contentItem.height - height/2
            enabled: uuid.length > 0 || editor.text.length > 0

            text: uuid == ""
                //% "Send"
                ? qsTrId("jolla-store-la-send")
                : editor.text.length > 0
                  //% "Update"
                  ? qsTrId("jolla-store-la-update")
                  //% "Delete"
                  : qsTrId("jolla-store-la-delete")

            opacity: (editor.activeFocus || enabled) ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation {} }

            onClicked: {
                if (jollaStore.isOnline) {
                    Qt.inputMethod.commit()
                    jollaStore.sendReview(uuid,
                                          appUuid,
                                          editor.text,
                                          packageVersion)
                    editor.text = ""
                    editor.focus = false
                    reviewReady()
                } else {
                    //: Notification shown when the user tries to post a comment while
                    //: the device is offline.
                    //% "Cannot post comments while offline."
                    Notices.show(qsTrId("jolla-store-no-cannot_comment_offline"))
                }
            }
        }
    }
}
