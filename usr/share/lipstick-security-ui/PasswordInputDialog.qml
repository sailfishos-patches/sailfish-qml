import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Lipstick 1.0

SystemDialog {
    id: root

    property alias password: passwordInput.text

    property bool cancelButtonVisible: true
    property bool cancelButtonEnabled: true
    property bool okButtonVisible: true
    property bool okButtonEnabled: true
    property int minimumLength: 4
    property alias maximumLength: passwordInput.maximumLength

    property alias okText: okButton.text
    property alias cancelText: cancelButton.text

    property alias titleText: header.title
    property alias titleColor: header.titleColor

    property alias descriptionText: descriptionLabel.text
    property alias transientWarningText: warningLabel.text
    property string warningText

    property alias suggestionText: suggestionLabel.text

    property int inputMethodHints

    property bool inputEnabled: true
    property bool requirePassword: true

    property alias echoMode: passwordInput.passwordEchoMode
    property alias passwordMaskDelay: passwordInput.passwordMaskDelay

    property bool suggestionsEnforced
    property bool suggestionsEnabled

    property bool _showSuggestion

    signal suggestionRequested()

    signal confirmed()
    signal canceled()

    function focusIn() {
        passwordInput.forceActiveFocus()
    }

    function suggestPassword(password) {
        passwordInput.text = password
        _showSuggestion = true
    }

    contentHeight: Math.min(screenHeight, flickable.contentHeight)

    onDismissed: {
        canceled()
    }

    SilicaFlickable {
        id: flickable

        width: parent.width
        height: Math.min(contentHeight, parent.parent.height)

        contentHeight: column.height

        Column {
            id: column
            width: flickable.width

            Expander {
                property int availableSpace: flickable.parent.parent.height - contentBelowHeader.height
                collapsedHeight: availableSpace < Theme.itemSizeHuge ? expandedHeight
                                                                     : Math.min(expandedHeight, availableSpace)
                expandedHeight: header.height

                SystemDialogHeader {
                    id: header
                }
            }

            Column {
                id: contentBelowHeader
                width: header.width
                anchors.horizontalCenter: parent.horizontalCenter

                Label {
                    id: descriptionLabel

                    x: (Screen.sizeCategory < Screen.Large) ? Theme.horizontalPageMargin : 0
                    width: header.width - 2*x
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeMedium
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    height: implicitHeight + (root.suggestionsEnabled ? Theme.paddingSmall : Theme.paddingLarge)
                }

                BackgroundItem {
                    id: suggestPasswordButton

                    onClicked: root.suggestionRequested()
                    visible: root.suggestionsEnabled
                    highlightedColor: "transparent"

                    Label {
                        id: suggestionLabel

                        //% "Suggest a password"
                        text: qsTrId("lipstick-jolla-home-security-ui-me-suggest-password")
                        color: suggestPasswordButton.highlighted ? Theme.highlightColor : Theme.primaryColor

                        width: parent.width
                               // TODO: Share padding value with SystemDialogHeader labels
                               - 2 * (Screen.sizeCategory < Screen.Large ? Theme.horizontalPageMargin : 0)
                        horizontalAlignment: Text.AlignHCenter
                        anchors.centerIn: parent
                    }
                }

                PasswordField {
                    id: passwordInput

                    focus: true
                    focusOutBehavior: FocusBehavior.KeepFocus
                    inputMethodHints: root.inputMethodHints
                                      | Qt.ImhNoPredictiveText
                                      | Qt.ImhSensitiveData
                                      | Qt.ImhNoAutoUppercase
                                      | Qt.ImhHiddenText
                                      | Qt.ImhMultiLine // This stops the text input hiding the keyboard when enter is pressed.

                    _appWindow: undefined // suppresses warnings, TODO: fix password field magnifier
                    color: Theme.highlightColor
                    cursorColor: Theme.highlightColor
                    placeholderColor: Theme.secondaryHighlightColor
                    textMargin: 2*Theme.paddingLarge
                    textTopMargin: Theme.paddingLarge
                    showEchoModeToggle: passwordEchoMode == TextInput.Normal
                    echoMode: (!showEchoModeToggle || _usePasswordEchoMode) && !root._showSuggestion
                              ? passwordEchoMode
                              : TextInput.Password
                    enabled: root.requirePassword && root.inputEnabled && !(root.suggestionsEnforced && root._showSuggestion)
                    visible: root.requirePassword
                    placeholderText: ""
                    labelVisible: false

                    EnterKey.enabled: root.okButtonEnabled && root.okButtonVisible && length >= root.minimumLength
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: root.confirmed()

                    VerticalAutoScroll.bottomMargin: okButton.height + warningItem.height

                    onTextChanged: {
                        warningLabel.text = root.warningText
                        root._showSuggestion = false
                    }

                    validator: RegExpValidator {
                        regExp: {
                            if (passwordInput.inputMethodHints & Qt.ImhDigitsOnly) {
                                return /[0-9]*/
                            } else if (passwordInput.inputMethodHints & Qt.ImhLatinOnly) {
                                return /[ -~¡-ÿ]*/
                            } else {
                                return  /.*/
                            }
                        }
                    }
                }

                Item {
                    id: warningItem
                    x: passwordInput.x
                    width: passwordInput.width
                    height: warningLabel.y + warningLabel.height

                    Label {
                        id: warningLabel

                        x: passwordInput.textLeftMargin
                        y: text !== "" ? 0 : -height
                        width: passwordInput.width
                        opacity: text !== "" ? 1 : 0
                        leftPadding: passwordInput.leftTextMargin
                        rightPadding: passwordInput.rightTextMargin
                        color: passwordInput.highlighted ? Theme.highlightColor : Theme.primaryColor
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeSmall

                        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                        Behavior on opacity { FadeAnimator {} }
                    }
                }

                Row {
                    SystemDialogTextButton {
                        id: cancelButton

                        width: header.width / 2
                        bottomPadding: Theme.paddingLarge
                        visible: root.cancelButtonVisible
                        enabled: root.cancelButtonEnabled
                        onClicked: root.canceled()

                        //% "Cancel"
                        text: qsTrId("lipstick-jolla-home-security-ui-bt-cancel")
                    }

                    SystemDialogTextButton {
                        id: okButton
                        width: header.width / 2
                        bottomPadding: Theme.paddingLarge
                        visible: root.okButtonVisible
                        enabled: root.okButtonEnabled
                                 && (!root.requirePassword || passwordInput.length >= root.minimumLength)
                        onClicked: root.confirmed()

                        //% "Ok"
                        text: qsTrId("lipstick-jolla-home-security-ui-bt-ok")
                    }
                }
            }
        }
    }
}
