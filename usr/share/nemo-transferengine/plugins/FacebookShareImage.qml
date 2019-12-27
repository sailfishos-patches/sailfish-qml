import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.thumbnailer 1.0
import Sailfish.TransferEngine 1.0

ShareDialog {
    id: root

    property real scalePercent: 1.0
    property int _listWidth: root.isPortrait ? Screen.width : Screen.height - (Screen.height / 3)

    onAccepted: {
        shareItem.start()
    }

    SailfishShare {
        id: shareItem
        source: root.source
        metadataStripped: true
        serviceId: root.methodId
        mimeType: fileInfo.mimeType
        userData: {"description": descriptionTextField.text,
                   "accountId": root.accountId,
                   "scalePercent": root.scalePercent}
    }

    FileInfo {
        id: fileInfo
        source: root.source
    }

    SilicaFlickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: dialogHeader.height + Theme.paddingLarge +
                       (root.isPortrait
                        ? previewColumn.height + settingsList.implicitHeight
                        : settingsList.implicitHeight)

        VerticalScrollDecorator {}

        DialogHeader {
            id: dialogHeader
            spacing: 0
            //: Title for page enabling user to share files with others
            //% "Share"
            acceptText: qsTrId("webshare-he-share_heading")
        }

        Column {
            id: previewColumn
            y: dialogHeader.height
            width: root.isPortrait ? Screen.width : Screen.height / 3
            spacing: Theme.paddingMedium

            PreviewImage {
                width: parent.width
                height: root.isPortrait ? Screen.height / 3 : Screen.height / 3
                source: root.source
                mimeType: shareItem.mimeType
                metadataStripped: shareItem.metadataStripped
                fileSize: fileInfo.size
            }

            Label {
                x: root.isPortrait ? Theme.horizontalPageMargin : 0
                width: previewColumn.width - x*2
                horizontalAlignment: Qt.AlignRight
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
                text: fileInfo.fileName
            }
        }

        Column {
            id: settingsList
            width: root._listWidth

            anchors {
                left: root.isPortrait ? previewColumn.left : previewColumn.right
                leftMargin: root.isPortrait ? 0 : Theme.paddingMedium
                top: root.isPortrait ? previewColumn.bottom : previewColumn.top
                topMargin: Theme.paddingMedium
                right: parent.right
            }

            TextField {
                id: descriptionTextField
                width: parent.width

                //: Image description
                //% "Description"
                label: qsTrId("webshare-la-description")

                //: Placeholder text for image description
                //% "Add a description"
                placeholderText: qsTrId("webshare-ph-description")

                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: root.focus = true

                textLeftMargin: root.isPortrait ? Theme.horizontalPageMargin : Theme.paddingLarge
            }

            ComboBox {
                id: scaleComboBox
                currentIndex: 3
                leftMargin: root.isPortrait ? Theme.horizontalPageMargin : Theme.paddingLarge

                //: Image scale
                //% "Scale image"
                label: qsTrId("webshare-la-scale_image")

                menu: ContextMenu {
                    //: Image scale is 25%
                    //% "25 %"
                    MenuItem { text: qsTrId("webshare-va-25_percent"); onClicked: root.scalePercent = 0.25 }
                    //: Image scale is 50%
                    //% "50 %"
                    MenuItem { text: qsTrId("webshare-va-50_percent"); onClicked: root.scalePercent = 0.5 }
                    //: Image scale is 75%
                    //% "75 %"
                    MenuItem { text: qsTrId("webshare-va-75_percent"); onClicked: root.scalePercent = 0.75  }
                    //: Image scale is original
                    //% "original"
                    MenuItem { text: qsTrId("webshare-va-original"); onClicked: root.scalePercent = 1 }
                }
            }

            TextSwitch {
                //: Include image metadata
                //% "Include metadata"
                text: qsTrId("webshare-me-include_metadata")
                checked: !shareItem.metadataStripped
                onCheckedChanged: shareItem.metadataStripped = !checked
                leftMargin: root.isPortrait ? Theme.horizontalPageMargin : Theme.paddingLarge
            }

            Column {
                id: facebookInfo
                x: root.isPortrait ? Theme.horizontalPageMargin : Theme.paddingLarge

                spacing: Theme.paddingMedium

                Column {
                    Label {
                        color: Theme.highlightColor
                        text: root.accountName
                    }
                    Label {
                        width: settingsList.width - Theme.horizontalPageMargin - facebookInfo.x
                        color: Theme.secondaryHighlightColor
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeSmall
                        text: root.displayName
                    }
                }

                Column {
                    Label {
                        color: Theme.highlightColor
                        //: Destination folder name for FB sharing
                        //% "Destination folder"
                        text: qsTrId("webshare-la-destination_folder")
                    }
                    Label {
                        width: settingsList.width - Theme.horizontalPageMargin - facebookInfo.x
                        color: Theme.secondaryHighlightColor
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeSmall
                        // TODO: This should come from the share plugin
                        //: Describes where mobile uploads will go. %1 is an operating system name
                        //% "Mobile uploads from %1"
                        text: qsTrId("webshare-la-uploads-text").arg(aboutSettings.operatingSystemName)
                    }
                }
            }
        }
    }

    AboutSettings {
        id: aboutSettings
    }
}
