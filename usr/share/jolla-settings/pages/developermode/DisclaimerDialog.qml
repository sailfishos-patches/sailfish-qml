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
                acceptText: qsTrId("settings_developermode-bu-accept")
                //% "Developer terms"
                title: qsTrId("settings_developermode-lb-developer_terms")
            }

            Label {
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.WordWrap
                textFormat: Text.AutoText

                //% "Notice. In developer mode, you can enable features that when used incorrectly can cause permanent damage both to your device and/or content.<br><br>Enabling developer mode may void your warranty.<br><br>Device needs to be rebooted after enabling developer mode. During that time you are not able to make or receive any phone calls.<br><br>Accepting these terms enables developer mode.</p>"
                text: qsTrId("settings_developermode-lb-disclaimer_text")
            }
        }
    }
}
