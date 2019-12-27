import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking 1.0
import Sailfish.Settings.Networking.Vpn 1.0

Dialog {
    id: root

    property Page mainPage

    canAccept: false
    forwardNavigation: false

    Column {
        width: parent.width

        DialogHeader {
            id: pageHeader

            //% "Import .ovpn file"
            title: qsTrId("settings_network-he-vpn_import_ovpn")
            acceptText: ''
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - x*2

            //% "Importing a file makes the set up process easier by filling out many options automatically.<br>Choose 'Skip' to set up OpenVPN manually."
            text: qsTrId("settings_network-he-vpn_import_ovpn_desc")
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

            //% "Import file"
            text: qsTrId("settings_network-bt-import_file")
            onClicked: {
                var obj = pageStack.animatorPush("Sailfish.Pickers.FilePickerPage", {
                    nameFilters: [ '*.ovpn' ],
                    popOnSelection: false
                })
                obj.pageCompleted.connect(function(picker) {
                    picker.selectedContentPropertiesChanged.connect(function() {
                        var path = picker.selectedContentProperties['filePath']
                        VpnTypes.importOvpnFile(pageStack, mainPage, path)
                    })
                })
            }
        }

        Button {
            ButtonLayout.newLine: true

            //% "Skip"
            text: qsTrId("settings_network-bt-skip_import")
            onClicked: {
                pageStack.animatorReplace(VpnTypes.editDialogPath("openvpn"), {
                    newConnection: true,
                    acceptDestination: root.mainPage
                })
            }
        }
    }
}

