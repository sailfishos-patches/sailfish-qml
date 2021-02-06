import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate

Page {
    id: root
    property alias text: label.plainText

    SilicaPrivate.BackgroundRectangle {
        anchors.fill: parent
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width

            PageHeader {
                id: header
                //% "QR-code"
                title: qsTrId("jolla-camera-la-qr_code_header")
            }

            LinkedLabel {
                id: label
                x: Theme.horizontalPageMargin
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                linkColor: Theme.highlightColor
                shortenUrl: true
                width: parent.width - Theme.highlightColor
                height: Math.max(flickable.height - header.height - button.height, implicitHeight) - Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: lineCount > 5 ? Text.AlignLeft : Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            Button {
                id: button
                //% "Copy"
                text: qsTrId("jolla-camera-la-qr_code_copy")
                preferredWidth: Screen.sizeCategory < Screen.Large && isPortrait
                                                    ? parent.width - Theme.horizontalPageMargin*2
                                                    : Theme.buttonWidthLarge
                onClicked: Clipboard.text = root.text
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        VerticalScrollDecorator {}
    }
}
