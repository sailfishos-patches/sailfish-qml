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

    function input(text) {
        var cursorPosition = textField.cursorPosition
        var oldtext = textField.text
        var left = oldtext.substr(0, cursorPosition)
        var right = oldtext.substr(cursorPosition, oldtext.length)

        asYouTypeFormatter.rawPhoneNumber = left + text
        cursorPosition = asYouTypeFormatter.lastPosition
        asYouTypeFormatter.rawPhoneNumber += right

        textField.cursorPosition = cursorPosition
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
        x: Theme.horizontalPageMargin
        height: parent.height
        icon.source: "image://theme/icon-m-clipboard"
        enabled: Clipboard.text.length < 30 && Person.normalizePhoneNumber(Clipboard.text).length
        opacity: enabled ? 1 : 0
        Behavior on opacity { FadeAnimator {} }

        onClicked: numberField.input(Person.normalizePhoneNumber(Clipboard.text))
    }


    IconButton {
        id: backspaceButton
        property bool deleted

        function backspace() {
            Qt.inputMethod.commit() // just in case something managed to enter preedit
            var selectionStart = textField.selectionStart
            var selectionEnd = textField.selectionEnd
            var offset = selectionStart === selectionEnd ? -1 : 0
            var oldtext = textField.text
            var left = oldtext.substr(0, selectionStart + offset)
            var right = oldtext.substr(selectionEnd, oldtext.length)

            asYouTypeFormatter.rawPhoneNumber = left
            var cursorPosition = asYouTypeFormatter.lastPosition
            asYouTypeFormatter.rawPhoneNumber += right

            textField.cursorPosition = cursorPosition
        }

        onPressed: deleted = false
        onClicked: {
            if (!deleted) {
                backspace()
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
            onTriggered: backspaceButton.backspace()
        }
    }
}
