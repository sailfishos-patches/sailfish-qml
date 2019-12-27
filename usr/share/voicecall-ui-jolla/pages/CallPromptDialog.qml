import QtQuick 2.1
import QtQuick.Window 2.1
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Telephony 1.0

SystemDialog {
    id: root

    property alias number: numberLabel.text
    property bool _showSimSelector

    property real _buttonHeight: _showSimSelector ? simSelector.height : buttonRow.height

    //% "Call requested"
    title: qsTrId("voicecall-he-call_prompt-call_requested")
    contentHeight: content.height + _buttonHeight
    Behavior on _buttonHeight { NumberAnimation { easing.type: Easing.InOutQuad } }

    function closeDialog()
    {
        if (!visible) {
            destroy(200)
        }
    }

    onVisibleChanged: if (!visible) closeDialog()

    Column {
        id: content
        width: parent.width

        SystemDialogHeader {
            id: header

            title: root.title
            //% "Allow calling to"
            description: qsTrId("voicecall-la-call_prompt-allow_calling_to")
        }
        Label {
            id: numberLabel
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin
            }
            truncationMode: TruncationMode.Fade
            horizontalAlignment: contentWidth > width ? Text.AlignLeft : Text.AlignHCenter
        }
        Item { width: 1; height: Theme.paddingLarge }
    }
    Row {
        id: buttonRow
        y: content.height
        anchors.horizontalCenter: parent.horizontalCenter
        height: Math.max(cancel.implicitHeight, call.implicitHeight)
        opacity: _showSimSelector ? 0.0 : 1.0
        Behavior on opacity { FadeAnimator {} }

        SystemDialogTextButton {
            id: cancel

            width: header.width / 2
            height: parent.height
            //% "Cancel"
            text: qsTrId("voicecall-la-call_prompt-cancel")
            onClicked: {
                lower()
                closeDialog()
            }
        }
        SystemDialogTextButton {
            id: call

            width: header.width / 2
            height: parent.height
            //% "Call now"
            text: qsTrId("voicecall-la-call_prompt-call_now")

            onClicked: {
                if (telephony.promptForSim(number)) {
                    _showSimSelector = true
                } else {
                    telephony.dialNumberOrService(number)
                    lower()
                    closeDialog()
                }
            }
        }
    }
    SimPicker {
        id: simSelector
        y: content.height
        showBackground: true
        enabled: _showSimSelector
        opacity: _showSimSelector ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation {} }
        onSimSelected: {
            telephony.dialNumberOrService(number, modemPath)
            lower()
            closeDialog()
            _showSimSelector = false
        }
    }
}
