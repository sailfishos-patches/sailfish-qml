import QtQuick 2.0
import Sailfish.Silica 1.0
import Connman 0.2
import Sailfish.Pickers 1.0
import Sailfish.Settings.Networking 1.0
import "../netproxy"

Dialog {
    id: root

    forwardNavigation: false
    canNavigateForward: false

    property QtObject network

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                //% "Forget network"
                text: qsTrId("settings_network-me-ethernet-forget_network")
                enabled: root.network
                onClicked: {
                    var network = root.network
                    pageStack.pop()
                    network.autoConnect = false;
                    network.requestDisconnect()
                    network.remove()
                    root.network = null
                }
            }
        }

        Column {
            id: content

            width: parent.width

            DialogHeader {
                id: dialogHeader
                acceptText: ""

                //% "Save"
                cancelText: qsTrId("settings_network-he-ethernet-save")

                Label {
                    parent: dialogHeader.extraContent
                    text: root.network ? root.network.name : "Testing testing"
                    color: Theme.highlightColor
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    font {
                        pixelSize: Theme.fontSizeLarge
                        family: Theme.fontFamilyHeading
                    }
                    anchors {
                        right: parent.right
                        rightMargin: -Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }

                    horizontalAlignment: Qt.AlignRight
                }
            }

            AdvancedSettingsColumn {
                id: advancedSettingsColumn
                network: root.network
                globalProxyConfigPage: Qt.resolvedUrl("../advanced-networking/mainpage.qml")
            }
        }
        VerticalScrollDecorator {}
    }
}
