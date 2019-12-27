import QtQuick 2.1
import QtQuick.Window 2.1
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

SystemDialogWindow {
    id: classZeroDialog

    property string text

    category: SystemDialogWindow.Alarm

    ApplicationWindow {
        // work around Page not finding window instance as non root item
        id: __silica_applicationwindow_instance
        _defaultLabelFormat: Text.PlainText
        cover: undefined
        initialPage: dialogPage
    }

    Component {
        id: dialogPage
        Page {
            SilicaFlickable {
                anchors.fill: parent
                contentHeight: height

                PullDownMenu {
                    quickSelect: true
                    MenuItem {
                        //% "Copy to Clipboard"
                        text: qsTrId("messages-me-message_copy_clipboard")
                        onClicked: {
                            Clipboard.text = classZeroDialog.text
                            classZeroDialog.close()
                        }
                    }
                }

                PushUpMenu {
                    quickSelect: true
                    MenuItem {
                        //% "Discard"
                        text: qsTrId("messages-me-dialog_discard")
                        onClicked: classZeroDialog.close()
                    }
                }

                PulleyAnimationHint {
                    anchors.fill: parent
                    pushUpHint: true
                }

                Image {
                    id: topIcon
                    anchors {
                        top: parent.top
                        topMargin: Theme.paddingLarge
                        horizontalCenter: parent.horizontalCenter
                    }
                    source: "image://theme/icon-l-message?" + Theme.highlightColor
                }

                Image {
                    anchors {
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingLarge
                        horizontalCenter: parent.horizontalCenter
                    }
                    source: "image://theme/icon-l-dismiss?" + Theme.highlightColor
                }

                Label {
                    id: messageText
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        margins: Theme.horizontalPageMargin + Theme.paddingLarge
                    }

                    horizontalAlignment: Qt.AlignHCenter
                    font.pixelSize: Theme.fontSizeLarge
                    color: Theme.primaryColor
                    wrapMode: Text.Wrap

                    onYChanged: {
                        if (parent.height > 0 && y <= topIcon.y + topIcon.height + Theme.paddingLarge)
                            messageText.font.pixelSize = Theme.fontSizeMedium
                    }

                    text: classZeroDialog.text
                }
            }
        }
    }
}
