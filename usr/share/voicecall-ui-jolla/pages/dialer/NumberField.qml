import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import Sailfish.Telephony 1.0
import org.nemomobile.time 1.0
import org.nemomobile.contacts 1.0

MouseArea {
    id: numberField

    property int rightMargin: Theme.horizontalPageMargin
    property bool active
    property alias text: asYouTypeFormatter.rawPhoneNumber
    property bool textFieldEmpty: textField.text.length === 0
    property alias topPadding: textField.y
    property var keypad

    signal callKeyPressed()

    function input(text, backspace, del) {
        Qt.inputMethod.commit() // just in case something managed to enter preedit
        var selectionStart = textField.selectionStart
        var selectionEnd = textField.selectionEnd
        var offset = selectionStart === selectionEnd ? -1 : 0
        var leftEndOffset = backspace ? offset : 0
        var rightStartOffset = del ? -offset : 0

        var oldtext = textField.text

        // When pressing backspace or delete, make sure to always delete a dialable digit
        if (offset !== 0 && (selectionStart + leftEndOffset) != (selectionEnd + rightStartOffset)) {
            var erased = oldtext.substr(selectionStart + leftEndOffset, selectionEnd + rightStartOffset - selectionStart - leftEndOffset)
            if (!(/[0-9\+\#\*]/.test(erased))) {
                if (backspace) {
                    leftEndOffset--
                } else if (del) {
                    rightStartOffset++
                }
            }
        }

        var left = oldtext.substr(0, selectionStart + leftEndOffset)
        var right = oldtext.substr(selectionEnd + rightStartOffset, oldtext.length - selectionEnd - rightStartOffset)

        asYouTypeFormatter.rememberPosition = true
        asYouTypeFormatter.rawPhoneNumber = left + text
        asYouTypeFormatter.rememberPosition = false
        asYouTypeFormatter.rawPhoneNumber += right

        textField.cursorPosition = asYouTypeFormatter.lastPosition

        if (backspace || del) {
            backspaceButton.deleted = true
        }
    }

    function pressBackspace() {
        input("", true, false)
    }

    function pressDelete() {
        input("", false, true)
    }

    x: Math.max(0, (!!keypad ? keypad._horizontalPadding : 0) - backspaceButton.width - backspaceButton.anchors.rightMargin)
    height: hugeFontMetrics.height
    width: parent.width - 2*x
    drag.filterChildren: true
    onActiveChanged: {
        if (active) {
            textField.forceActiveFocus()
        }
    }

    AsYouTypeFormatter {
        id: asYouTypeFormatter
        regionCode: telephony.country
    }

    TextField {
        id: textField

        text: asYouTypeFormatter.formattedNumber
        background: null
        color: Theme.highlightColor
        font.pixelSize: hugeFontMetrics.boundingRect(text).width > (width - textLeftMargin - textRightMargin) ? Theme.fontSizeExtraLarge
                                                                                                              : hugeFontMetrics.font.pixelSize
        enableSoftwareInputPanel: false
        validator: RegExpValidator { regExp: /^[0-9\+\-\#\*\ ]{6,}$/ }
        labelVisible: false
        _cursorBlinkEnabled: false
        textTopMargin: Theme.paddingMedium
        textLeftMargin: pasteButton.width + pasteButton.x + Theme.paddingMedium
        textRightMargin: backspaceButton.width + backspaceButton.anchors.rightMargin + Theme.paddingMedium
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(Math.max(implicitWidth, parent.width),
                        parent.width + (pasteButton.enabled ? 0 : pasteButton.width + Theme.paddingMedium))
        // ImhDialableCharactersOnly would be good, but atm changes virtual keyboard layout during hiding
        // Some extra measure to prevent non-validating preedit
        inputMethodHints: Qt.ImhNoPredictiveText

        onActiveFocusChanged: {
            if (activeFocus) {
                Qt.inputMethod.hide() // we have custom keypad for this
            }
        }

        Component.onCompleted: {
            // We want to hook up to the event on the _editor itself rather than the textField that wraps it
            // Note: This only applies to a hw keyboard, since the software input panel is disabled.
            //       It wouldn't work with the sw input panel because the preedit prevents us from intercepting individual key presses.
            textField._editor.Keys.onPressed.connect(function(event) {
                // Intercept individual key strokes so that we can validate them and apply the custom formatting
                switch (event.key) {
                case Qt.Key_Left:
                case Qt.Key_Right:
                case Qt.Key_Up:
                case Qt.Key_Down:
                case Qt.Key_Home:
                case Qt.Key_End:
                    // Don't catch these, let the user position the cursor with the keyboard
                    return
                case Qt.Key_Enter:
                case Qt.Key_Return:
                case Qt.Key_Call:
                    numberField.callKeyPressed()
                    break
                case Qt.Key_Backspace:
                    pressBackspace()
                    break
                case Qt.Key_Delete:
                    pressDelete()
                    break
                default:
                    // Ignore empty text from the hw keyboard
                    if (!event.text)
                        return

                    // Only allow entering dialable characters and whitespace
                    if (/[0-9\+\-\#\*\ \,]+/.test(event.text))
                        input(event.text)

                    break
                }

                event.accepted = true
            })
        }
    }

    FontMetrics {
        id: hugeFontMetrics
        font.pixelSize: Theme.fontSizeHuge
    }

    Label {
        enabled: textFieldEmpty
        opacity: enabled ? 1 : 0
        Behavior on opacity { FadeAnimator {} }

        anchors.verticalCenter: parent.verticalCenter
        x: textField.textLeftMargin
        fontSizeMode: Text.HorizontalFit
        font.pixelSize: Theme.fontSizeExtraLarge
        color: Theme.secondaryHighlightColor
        verticalAlignment: Text.AlignVCenter
        width: parent.width - textField.textLeftMargin - textField.textRightMargin
        //% "Enter phone number"
        text: qsTrId("voicecall-ph-enter_phone_number")
    }

    IconButton {
        id: pasteButton
        preventStealing: clearClipboardPopup.visible
        x: Theme.horizontalPageMargin
        height: parent.height
        icon.source: "image://theme/icon-m-clipboard"
        enabled: Clipboard.text.length < 30 && Person.normalizePhoneNumber(Clipboard.text).length
        opacity: enabled ? 1 : 0
        Behavior on opacity { FadeAnimator {} }

        onClicked: numberField.input(Person.normalizePhoneNumber(Clipboard.text))

        onPressAndHold: {
            clearClipboardPopup.visible = true
        }
        onReleased: {
            if (clearClipboardPopup.visible && clearClipboardPopup.containsMouse)
                Clipboard.text = ""
            clearClipboardPopup.visible = false
        }
        onCanceled: clearClipboardPopup.visible = false
        onPositionChanged: {
            if (!clearClipboardPopup.visible) {
                return
            }

            var pos = mapToItem(clearClipboardPopup, mouse.x, mouse.y)
            clearClipboardPopup.containsMouse = clearClipboardPopup.contains(Qt.point(pos.x, pos.y - clearClipboardPopup.clearPasteTouchDelta))
        }

        Rectangle {
            id: clearClipboardPopup

            property bool containsMouse
            property bool isLargeScreen: Screen.sizeCategory > Screen.Medium
            property real scaleRatio: isLargeScreen ? Screen.width / 580 : Screen.width / 480
            property int clearPasteTouchDelta: 20*scaleRatio

            visible: false
            anchors.left: pasteButton.left
            anchors.bottom: pasteButton.top
            width: clearLabel.width + 50*scaleRatio
            height: clearLabel.height + 50*scaleRatio
            radius: 10*scaleRatio
            color: Theme.colorScheme === Theme.LightOnDark
                   ? Qt.darker(Theme.highlightBackgroundColor, 1.2)
                   : Qt.lighter(Theme.highlightBackgroundColor, 1.4)

            onVisibleChanged: containsMouse = false

            Label {
                id: clearLabel
                anchors.centerIn: parent
                color: parent.containsMouse ? Theme.primaryColor : Theme.highlightColor
                //% "Clear clipboard"
                text: qsTrId("number_input-la-clear_clipboard")
            }
        }
    }

    IconButton {
        id: backspaceButton
        property bool deleted

        onPressed: deleted = false
        onClicked: {
            if (!deleted) {
                pressBackspace()
            }
        }

        anchors {
            rightMargin: numberField.rightMargin
            right: parent.right
            verticalCenter: textField.verticalCenter
        }

        enabled: !textFieldEmpty
        opacity: enabled ? 1 : 0
        Behavior on opacity { FadeAnimator {} }
        height: parent.height
        objectName: "backspaceButton"
        icon.source: "image://theme/icon-m-backspace"

        Timer {
            running: !textFieldEmpty && backspaceButton.down
            interval: 175
            repeat: true
            onTriggered: pressBackspace()
        }
    }
}
