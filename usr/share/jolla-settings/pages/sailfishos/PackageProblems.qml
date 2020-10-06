import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaItem {
    height: packagesLabel.height + packagesText.height + Theme.paddingMedium*2
    width: parent.width

    Rectangle {
        id: background
        anchors.fill: parent
        color: Theme.rgba(Theme.highlightDimmerColor, 0.5)
    }

    Label {
        id: packagesLabel
        x: Theme.horizontalPageMargin
        width: parent.width - Theme.horizontalPageMargin*2
        height: implicitHeight + Theme.paddingLarge*2
        wrapMode: Text.Wrap
        //% "Please uninstall following before proceeding with the Sailfish OS update"
        text: qsTrId("settings_sailfishos-la-recommend_uninstall_packages")
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeLarge
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        id: packagesText
        anchors.top: packagesLabel.bottom
        width: parent.width
        wrapMode: Text.Wrap
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeMedium
        textFormat: Text.StyledText
        horizontalAlignment: Text.AlignHCenter
        text: storeIf.offendingPackagesList.join("<br/>")
    }
}
