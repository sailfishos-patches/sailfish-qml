import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.voicecall.settings.translations 1.0

Page {
    id: root

    property bool saving
    property bool enableAppendAnimation
    property bool enableHeightAnimation

    onStatusChanged: {
        if (status === PageStatus.Deactivating) {
            quickMessagesModel.save()
        }
    }

    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state !== Qt.ApplicationActive) {
                quickMessagesModel.save()
            }
        }
    }

    SilicaListView {
        id: quickMessagesListView

        anchors.fill: parent
        pullDownMenu: quickMessagesPullDownMenu
        model: QuickMessagesModel {
            id: quickMessagesModel
        }
        header: Column {
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                //: "Page header in the Quick message reply page."
                //% "Quick message reply"
                title: qsTrId("settings_phone-he-quick_message_reply_page")
            }

            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                spacing: Theme.paddingMedium

                Label {
                    width: parent.width
                    color: Theme.highlightColor
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall

                    //: Detailed description that is shown on the quick messages page.
                    //% "Configure up to five quick reply messages that you can send after silencing an incoming call. Your settings are automatically saved."
                    text: qsTrId("settings_phone-la-quick_message_reply_detailed_description")
                }

                Label {
                    width: parent.width
                    color: Theme.errorColor
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    visible: quickMessagesModel.hasError

                    //: Shown when the voicecall-ui settings folder doesn't exist and could not be created.
                    //% "Can't save quick replies."
                    text: qsTrId("settings_phone-la-quick_message_reply_error_cant_save")
                }
            }
        }
        delegate: TextArea {
            id: messageTextField

            width: parent.width
            labelVisible: false
            text: model.display
            textTopMargin: Theme.paddingLarge

            height: enableAppendAnimation ? 0 : implicitHeight
            opacity: enableAppendAnimation ? 0.0 : 1.0

            //% "Quick reply message"
            placeholderText: qsTrId("settings_phone-ph-quick_message_reply_text")

            onTextChanged: {
                if (model.display !== text) {
                    model.display = text
                }
            }
            Component.onCompleted: {
                if (enableAppendAnimation) {
                    showAnimation.start()
                } else {
                    height = Qt.binding(function() { return implicitHeight })
                    opacity = 1.0
                }
            }

            rightItem: IconButton {
                onClicked: {
                    if (messageTextField.text) {
                        messageTextField.text = ""
                    } else {
                        enableHeightAnimation = true
                        deleteAnimation.start()
                    }
                }

                width: icon.width
                height: icon.height
                enabled: quickMessagesModel.count > 1
                icon.source: messageTextField.text.length > 0
                             ? "image://theme/icon-splus-clear"
                             : "image://theme/icon-splus-remove"
                opacity: clearableField.text.length > 0 ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation {} }
            }

            SequentialAnimation {
                id: showAnimation

                ScriptAction {
                    script: {
                        // Remove bindings, these will be handled by the animation from now on
                        messageTextField.height = 0
                        messageTextField.opacity = 0.0
                    }
                }
                NumberAnimation {
                    target: messageTextField
                    property: "height"
                    to: messageTextField.implicitHeight
                    duration: 100
                    loops: enableHeightAnimation ? 1 : 0
                }
                FadeAnimation {
                    target: messageTextField
                    to: 1.0
                    duration: 100
                }
                ScriptAction {
                    script: {
                        messageTextField.height = Qt.binding(function() { return messageTextField.implicitHeight })
                    }
                }
            }

            SequentialAnimation {
                id: deleteAnimation

                ScriptAction {
                    script: {
                        messageTextField.enabled = false

                        // Remove bindings, these will be handled by the animation from now on
                        messageTextField.height = messageTextField.height
                        messageTextField.opacity = messageTextField.opacity
                    }
                }
                FadeAnimation {
                    target: messageTextField
                    to: 0.0
                    duration: 100
                }
                NumberAnimation {
                    target: messageTextField
                    property: "height"
                    to: 0
                    duration: 100
                    loops: enableHeightAnimation ? 1 : 0
                }
                ScriptAction {
                    script: {
                        quickMessagesModel.remove(index)
                    }
                }
            }
        }
        footer: BackgroundItem {
            width: parent.width
            height: addRow.height + 2 * addRow.y
            enabled: quickMessagesModel.count < 5
            opacity: enabled ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {} }

            onClicked: {
                enableAppendAnimation = true
                enableHeightAnimation = true
                quickMessagesModel.append("")
                quickMessagesListView.currentIndex = quickMessagesModel.count - 1
                quickMessagesListView.currentItem.forceActiveFocus()
            }

            Row {
                id: addRow

                width: parent.width - 2 * Theme.horizontalPageMargin
                x: Theme.horizontalPageMargin
                y: Theme.paddingMedium
                spacing: Theme.paddingMedium

                HighlightImage {
                    source: "image://theme/icon-m-add"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Label {
                    wrapMode: Text.Wrap
                    width: parent.width - parent.spacing - Theme.iconSizeMedium
                    anchors.verticalCenter: parent.verticalCenter

                    //% "Add quick reply"
                    text: qsTrId("settings_phone-la-quick_message_reply_add")
                }
            }
        }

        PullDownMenu {
            id: quickMessagesPullDownMenu

            MenuItem {
                //: Pulley menu item which resets the quick replies to the default values.
                //% "Reset to default"
                text: qsTrId("settings_phone-me-quick_message_reply_reset")
                onClicked: {
                    enableHeightAnimation = false
                    quickMessagesModel.reset()
                }
            }
        }
    }
}
