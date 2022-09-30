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

            property int internalPadding: Math.max(flickable.height
                                                   - header.height - label.height - button.height - Theme.paddingLarge*2,
                                                   Theme.paddingLarge*2) / 2

            width: parent.width

            PageHeader {
                id: header
                //% "QR-code"
                title: qsTrId("jolla-camera-la-qr_code_header")
            }

            Item {
                width: 1
                height: column.internalPadding
            }

            LinkedLabel {
                id: label

                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                linkColor: Theme.highlightColor
                shortenUrl: true
                horizontalAlignment: lineCount > 5 ? Text.AlignLeft : Text.AlignHCenter
            }

            Item {
                width: 1
                height: column.internalPadding
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
