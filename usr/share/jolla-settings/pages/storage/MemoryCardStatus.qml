import QtQuick 2.0
import Sailfish.Silica 1.0

Rectangle {
    property bool highlighted

    width: parent.width
    height: visible ? externalStorageWarning.implicitHeight + 2*Theme.paddingMedium : 0
    color: Theme.rgba(Theme.errorColor, Theme.highlightBackgroundOpacity)

    Label {
        id: externalStorageWarning

        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }

        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.errorColor

        //% "The file system is incompatible, formatting needed."
        text: qsTrId("settings_storage-la-incompatible_filesystem_error")
    }
}

