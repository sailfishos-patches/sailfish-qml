import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Gallery 1.0
import org.nemomobile.thumbnailer 1.0
import Sailfish.TransferEngine 1.0

ShareDialog {
    id: root

    property real scalePercent: 1.0
    property int _listWidth: root.isPortrait ? Screen.width : Screen.height - (Screen.width / 3)

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
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: Theme.paddingLarge + dialogHeader.height + (root.isPortrait ? previewColumn.height + settingsList.height
                                                                                   : Math.max(settingsList.height, previewColumn.height))

        DialogHeader {
            id: dialogHeader
            spacing: 0
            //: Title for page enabling user to share files with others
            //% "Share"
            acceptText: qsTrId("twittershare-he-share_heading")
        }

        Column {
            id: previewColumn
            y: dialogHeader.height
            width: root.isPortrait ? Screen.width : Screen.height / 3
            spacing: Theme.paddingMedium

            PreviewImage {
                width: parent.width
                height: Screen.height / 3
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

                //: Label indicating text area is used for entering tweet.
                //% "Tweet"
                label: qsTrId("twittershare-la-description")

                //: Placeholder text for tweet text area
                //% "My tweet"
                placeholderText: qsTrId("twittershare-ph-description")

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
                label: qsTrId("twittershare-la-scale_image")

                menu: ContextMenu {
                    //: Image scale is 25%
                    //% "25 %"
                    MenuItem { text: qsTrId("twittershare-va-25_percent"); onClicked: root.scalePercent = 0.25 }
                    //: Image scale is 50%
                    //% "50 %"
                    MenuItem { text: qsTrId("twittershare-va-50_percent"); onClicked: root.scalePercent = 0.5 }
                    //: Image scale is 75%
                    //% "75 %"
                    MenuItem { text: qsTrId("twittershare-va-75_percent"); onClicked: root.scalePercent = 0.75  }
                    //: Image scale is original
                    //% "original"
                    MenuItem { text: qsTrId("twittershare-va-original"); onClicked: root.scalePercent = 1 }
                }
            }

            TextSwitch {
                //: Include image metadata
                //% "Include metadata"
                text: qsTrId("twittershare-me-include_metadata")
                checked: !shareItem.metadataStripped
                onCheckedChanged: shareItem.metadataStripped = !checked
                leftMargin: root.isPortrait ? Theme.horizontalPageMargin : Theme.paddingLarge
            }

            Column {
                x: root.isPortrait ? Theme.horizontalPageMargin : Theme.paddingLarge

                Label {
                    color: Theme.highlightColor
                    text: root.accountName
                }
                Label {
                    width: root.width - Theme.paddingLarge*2
                    color: Theme.secondaryHighlightColor
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeSmall
                    text: root.displayName
                }
            }
        }
    }
}
