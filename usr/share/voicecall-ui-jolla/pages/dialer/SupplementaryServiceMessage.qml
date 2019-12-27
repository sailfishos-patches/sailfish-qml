import QtQuick 2.1
import QtQuick.Window 2.1
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

SystemDialogWindow {
    id: serviceDialog
    category: SystemDialogWindow.Alarm

    property var ofonoUSSD
    property alias message: label.text
    property alias title: pageHeader.text
    property bool busy
    property var properties
    onPropertiesChanged: {
        var str = ""
        for (var prop in properties) {
            //: Shows a supplementary service property and its value, e.g. for call forwarding "VoiceNoReply: +12345678"
            //% "%1: %2"
            str += qsTrId("voicecall-la-supplementary_property_pair").arg(prop).arg(properties[prop]) + "\n"
        }
        propLabel.text = str
    }

    function activate() {
        closeTimer.stop()
        showFullScreen()
        raise()
    }

    function deactivate() {
        lower()
        closeTimer.start()
    }

    function dismiss() {
        deactivate()
        if (ofonoUSSD.state !== "idle") {
            ofonoUSSD.cancel()
        }
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: serviceDialog.close()
    }

    function reset() {
        message = ""
        title = ""
        properties = {}
        textField.text = ""
    }

    ApplicationWindow {
        // ApplicationWindow isn't really designed for multiple instantiations.
        id: __silica_applicationwindow_instance
        _defaultLabelFormat: Text.PlainText
        cover: undefined
        initialPage: Page {
            id: page

            SilicaFlickable {
                id: flickable
                anchors.fill: parent
                contentHeight: Math.max(page.height, (content.visible ? content.height : busyContent.height) + 5*Theme.paddingLarge + 2*topDismissIcon.height)

                PulleyAnimationHint {
                    pullDownDistance: Theme.itemSizeLarge + Theme.itemSizeExtraSmall
                    anchors.fill: parent
                    enabled: !textField.activeFocus
                }

                PullDownMenu {
                    quickSelect: true
                    bottomMargin: Theme.itemSizeExtraSmall
                    MenuItem {
                        //% "Dismiss"
                        text: qsTrId("voicecall-la-me_dismiss")
                        onClicked: dismiss()
                    }
                }
                PushUpMenu {
                    quickSelect: true
                    topMargin: Theme.itemSizeExtraSmall
                    MenuItem {
                        //% "Dismiss"
                        text: qsTrId("voicecall-la-me_dismiss")
                        onClicked: dismiss()
                    }
                }

                Image {
                    id: topDismissIcon
                    y: Theme.paddingLarge
                    source: "image://theme/icon-l-dismiss?" + Theme.highlightColor
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Column {
                    id: content
                    property real availableHeight: flickable.contentHeight - 2*topDismissIcon.height - 4*Theme.paddingLarge
                    visible: opacity > 0.0
                    opacity: busy ? 0.0 : 1.0
                    Behavior on opacity { FadeAnimation {} }
                    width: parent.width
                    anchors {
                        top: topDismissIcon.bottom
                        topMargin: flickable.contentHeight == page.height ? (availableHeight - content.height)/2 : Theme.paddingLarge
                    }
                    spacing: Theme.paddingMedium

                    Label {
                        id: pageHeader

                        font.pixelSize: Theme.fontSizeExtraLarge
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - 2*Theme.horizontalPageMargin
                        wrapMode: Text.Wrap
                    }

                    Label {
                        id: label

                        visible: text !== ""
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 2*Theme.horizontalPageMargin
                        textFormat: Text.PlainText
                        font.pixelSize: lineCount <= 4 ? Theme.fontSizeLarge : Theme.fontSizeMedium
                        minimumPixelSize: Theme.fontSizeExtraSmall
                        wrapMode: Text.Wrap
                    }
                    Label {
                        id: propLabel

                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 2*Theme.horizontalPageMargin
                        textFormat: Text.PlainText
                        fontSizeMode: Text.HorizontalFit
                        minimumPixelSize: Theme.fontSizeExtraSmall
                    }
                    Item {
                        width: parent.width
                        height: textField.height
                        visible: ofonoUSSD.state === "user-response"
                        TextField {
                            id: textField
                            anchors.left: parent.left
                            anchors.right: sendButton.left
                            textRightMargin: Theme.paddingMedium
                            inputMethodHints: Qt.ImhDialableCharactersOnly
                            focus: visible

                            EnterKey.enabled: text.length > 0
                            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                            EnterKey.onClicked: ofonoUSSD.respondToService(textField.text)
                        }
                        IconButton {
                            id: sendButton
                            anchors {
                                right: parent.right
                                rightMargin: Theme.horizontalPageMargin
                            }
                            icon.source: "image://theme/icon-m-enter"
                            onClicked: ofonoUSSD.respondToService(textField.text)
                        }
                    }
                }
                Column {
                    id: busyContent
                    width: parent.width
                    spacing: Theme.paddingLarge
                    anchors.verticalCenter: parent.verticalCenter
                    visible: opacity > 0.0
                    opacity: 1.0 - content.opacity
                    BusyIndicator {
                        running: visible
                        size: BusyIndicatorSize.Large
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Label {
                        width: parent.width
                        color: Theme.highlightColor
                        horizontalAlignment: Text.AlignHCenter
                        //% "Service request in progress"
                        text: qsTrId("voicecall-la-ss_request_pending")
                        font.pixelSize: Theme.fontSizeLarge
                        wrapMode: Text.Wrap
                    }
                }
                Image {
                    source: "image://theme/icon-l-dismiss?" + Theme.highlightColor
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingLarge
                    }
                }
            }
        }
    }
}
