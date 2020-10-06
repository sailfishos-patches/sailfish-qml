/****************************************************************************************
**
** Copyright (c) 2020 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Vault 1.0
import Nemo.DBus 2.0

Column {
    id: root

    signal createAccount()

    width: parent ? parent.width : Screen.width
    spacing: Theme.paddingLarge

    Label {
        x: Theme.horizontalPageMargin
        width: parent.width - x*2
        font.family: Theme.fontFamilyHeading
        font.pixelSize: Theme.fontSizeExtraLarge
        wrapMode: Text.Wrap
        color: Theme.highlightColor

        //: No memory card or cloud account available for doing system backup
        //% "No cloud account or memory card available"
        text: qsTrId("vault-la-no_cloud account_or_memory_card_available")
    }

    Label {
        x: Theme.horizontalPageMargin
        width: parent.width - x*2
        height: implicitHeight + Theme.paddingLarge
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.highlightColor
        textFormat: Text.PlainText

        //% "Please insert a micro SD card and try again. Always use a dedicated card for storing your backups and keep it in a safe place."
        text: qsTrId("vault-la-insert_micro_sd_and_try_again")
    }

    Label {
        visible: BackupUtils.checkCloudAccountServiceAvailable()
        x: Theme.horizontalPageMargin
        width: parent.width - x*2
        height: implicitHeight + Theme.paddingLarge
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.highlightColor
        textFormat: Text.PlainText

        //% "Alternatively, create a cloud storage account with a third party service to safely store your backed up data."
        text: qsTrId("vault-la-create_cloud_storage_account_description")
    }

    Button {
        id: addAccountButton

        anchors.horizontalCenter: parent.horizontalCenter
        text: BackupUtils.addCloudAccountText
        visible: BackupUtils.checkCloudAccountServiceAvailable()

        onClicked: {
            root.createAccount()
        }
    }

    DBusInterface {
        id: settingsUi
        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"
    }
}
