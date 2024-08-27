import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Secrets 1.0
import Sailfish.Secrets.Ui 1.0
import org.nemomobile.systemsettings 1.0

SilicaFlickable {
    id: secretsResetView

    property alias text: infoLabel.text
    property alias header: colHeader.children
    signal success
    signal error
    signal started

    contentHeight: secretsResetColumn.height
    width: parent.width

    SecretsResetter {
        id: secretsResetter

        onSuccess: secretsResetView.success()
        onError: secretsResetView.error()
    }

    Column {
        id: secretsResetColumn
        width: parent.width
        padding: Theme.horizontalPageMargin
        topPadding: Theme.paddingLarge
        spacing: Theme.paddingLarge

        Item {
            id: colHeader
            width: parent.width - parent.padding
            // Assuming only a single child for this item
            height: children.length === 0 ? 0 : children[0].height
        }

        Label {
            id: infoLabel
            wrapMode: Text.Wrap
            width: parent.width - parent.padding
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeMedium

            //: Generic information presented to the user about resetting secrets data.
            //% "Affects all secrets data, including your keys, collectons, etc."
            text: qsTrId("secrets_ui-la-reset_secrets_data")
        }

        Button {
            //: Button that can clear all the secrets data.
            //% "Clear secrets data"
            text: qsTrId("secrets_ui-bt-reset_secrets_data")
            anchors.horizontalCenter: parent.horizontalCenter
            enabled: secretsResetView.enabled

            onClicked: {
                secretsResetView.started()
                secretsResetter.resetSecretsData()
            }
        }
    }

    VerticalScrollDecorator {}
}
