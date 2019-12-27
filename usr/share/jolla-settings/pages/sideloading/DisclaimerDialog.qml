import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: disclaimerDialog
    canAccept: true

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: disclaimerColumn.height + Theme.paddingLarge

        Column {
            id: disclaimerColumn

            width: parent.width

            DialogHeader {
                //% "Accept"
                acceptText: qsTrId("settings_sideloading-bu-accept")
                //% "Untrusted software terms"
                title: qsTrId("settings_sideloading-lb-untrusted_software_terms")
            }

            Label {
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.WordWrap
                textFormat: Text.AutoText

                //% "Notice. By installing and using untrusted software, you can cause permanent damage both to your product and/or content. The product manufacturer, seller and Jolla accept no liability whatsoever for any such damage. You install and use untrusted software at your own risk.<br><br>Installing and using untrusted software may void your warranty.<br><br>Accepting these terms is required to enable the possibility to install untrusted software."
                text: qsTrId("settings_sideloading-lb-disclaimer_text")
            }
        }
    }
}
