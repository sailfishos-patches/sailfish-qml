import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0

Dialog {
    id: root

    property Page mainPage

    canAccept: false
    forwardNavigation: false

    Column {
        width: parent.width

        DialogHeader {
            id: pageHeader

            //% "Import .ovpn file failed"
            title: qsTrId("settings_network-he-vpn_import_ovpn_failed")
            acceptText: ''
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - x*2

            //% "Choose 'Try again' to choose another file, or choose 'Skip' to set up OpenVPN manually."
            text: qsTrId("settings_network-he-vpn_import_ovpn_failed_desc")
            textFormat: Text.StyledText
            wrapMode: Text.Wrap

            font.pixelSize: Theme.fontSizeSmall
            color: Theme.highlightColor
        }
    }

    ButtonLayout {
        anchors {
            bottom: parent.bottom
            bottomMargin: importButton.height
            horizontalCenter: parent.horizontalCenter
        }

        preferredWidth: Theme.buttonWidthLarge

        Button {
            id: importButton

            //% "Try again"
            text: qsTrId("settings_network-bt-import_file_try_again")
            onClicked: {
                var obj = pageStack.animatorPush("Sailfish.Pickers.FilePickerPage", {
                    nameFilters: [ '*.ovpn' ],
                    popOnSelection: false
                })
                obj.pageCompleted.connect(function(picker) {
                    picker.selectedContentPropertiesChanged.connect(function() {
                        var path = picker.selectedContentProperties['filePath']
                        VpnTypes.importOvpnFile(pageStack, root.mainPage, path)
                    })
                })
            }
        }

        Button {
            ButtonLayout.newLine: true

            //% "Skip"
            text: qsTrId("settings_network-bt-skip_import_on_failure")
            onClicked: {
                pageStack.animatorReplace(VpnTypes.editDialogPath("openvpn"), {
                    newConnection: true,
                    acceptDestination: root.mainPage
                })
            }
        }
    }
}

