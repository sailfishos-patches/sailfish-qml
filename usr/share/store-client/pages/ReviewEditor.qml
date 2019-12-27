import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import org.nemomobile.notifications 1.0

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

        anchors {
            left: parent.left
            right: sendButtonArea.left
        }

        focusOutBehavior: FocusBehavior.KeepFocus
        textLeftMargin: horizontalMargin
        textRightMargin: 0
        font.pixelSize: Theme.fontSizeSmall
        //: Placeholder text for the comment field
        //% "Your comment"
        placeholderText: qsTrId("jolla-store-ph-comment")
        label: placeholderText
    }

    MouseArea {
        id: sendButtonArea
        anchors {
            fill: sendButtonText
            margins: -Theme.paddingLarge
        }
        enabled: uuid.length > 0 || editor.text.length > 0
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
                errorNotification.publish()
            }
        }

        Notification {
            id: errorNotification

            category: "x-jolla.store.error"
            //: Notification shown when the user tries to post a comment while
            //: the device is offline.
            //% "Cannot post comments while offline."
            previewBody: qsTrId("jolla-store-no-cannot_comment_offline")
        }
    }

    Label {
        id: sendButtonText
        anchors {
            right: parent.right
            rightMargin: horizontalMargin
            verticalCenter: editor.top
            verticalCenterOffset: editor.textVerticalCenterOffset + (editor._editor.height - height)
        }

        font.pixelSize: Theme.fontSizeSmall
        color: !sendButtonArea.enabled
               ? Theme.secondaryColor
               : sendButtonArea.pressed
                  ? Theme.highlightColor
                  : Theme.primaryColor
        opacity: (editor.activeFocus || sendButtonArea.enabled) ? 1.0 : 0.0

        text: uuid == ""
            //% "Send"
            ? qsTrId("jolla-store-la-send")
            : editor.text.length > 0
              //% "Update"
              ? qsTrId("jolla-store-la-update")
              //% "Delete"
              : qsTrId("jolla-store-la-delete")

        Behavior on opacity { FadeAnimation {} }
    }
}
