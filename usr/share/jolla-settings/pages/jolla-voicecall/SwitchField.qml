import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

FocusScope {
    property bool changed: (checked && systemNumber != number) || (!checked && systemNumber.length)
    property alias checked: textSwitch.checked
    property alias label: textSwitch.text
    property alias number: textField.text
    property alias busy: textSwitch.busy
    property bool error
    property bool showAccept
    property string systemNumber
    onSystemNumberChanged: reset()

    signal enterClicked()

    width: parent.width
    height: content.height

    VerticalAutoScroll.keepVisible: textField.activeFocus

    function reset() {
        number = systemNumber
        checked = systemNumber.length > 0
    }
    function result() {
        return checked ? number : ""
    }

    Column {
        id: content
        width: parent.width

        TextSwitch {
            id: textSwitch
            enabled: parent.enabled
            onClicked: {
                if (checked) {
                    textField.forceActiveFocus()
                }
            }
        }
        Item {
            width: parent.width
            height: textField.height * opacity
            opacity: textSwitch.checked && !busy ? 1.0 : Theme.opacityHigh
            Behavior on opacity { FadeAnimation {} }
            enabled: textSwitch.checked
            TextField {
                id: textField
                anchors {
                    left: parent.left
                    right: contactButton.left
                    verticalCenter: parent.verticalCenter
                }
                inputMethodHints: Qt.ImhDialableCharactersOnly
                enabled: textSwitch.checked
                EnterKey.onClicked: enterClicked()
                EnterKey.iconSource: showAccept ? "image://theme/icon-m-enter-accept" : "image://theme/icon-m-enter-close"
                textRightMargin: Theme.paddingMedium
            }
            IconButton {
                id: contactButton
                anchors {
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin - Theme.paddingLarge
                    verticalCenter: textField.verticalCenter
                    verticalCenterOffset: -Theme.paddingMedium
                }
                icon.source: "image://theme/icon-m-add"
                onClicked: {
                    var obj = pageStack.animatorPush(Qt.resolvedUrl("ContactSelector.qml"))
                    obj.pageCompleted.connect(function(page) {
                        page.numberSelected.connect(function(selectedNumber) {
                            pageStack.pop()
                            number = Person.normalizePhoneNumber(selectedNumber)
                        })
                    })
                }
            }
        }

        Button {
            //: Accept button
            //% "Accept"
            text: qsTrId("settings_voicecall-bt-accept_changes")
            visible: opacity > 0.0
            opacity: showAccept ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation {} }
            height: Theme.itemSizeSmall * opacity
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: {
                number = Person.normalizePhoneNumber(number)
                enterClicked()
            }
        }

        Label {
            id: errorLabel
            anchors {
                left: parent.left
                right: parent.right
                margins: Theme.paddingLarge
            }
            visible: error
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.Wrap
            //% "Changing call forwarding setting failed"
            text: qsTrId("settings_voicecall-la-changing_call_forwarding_failed")
        }
    }
}
