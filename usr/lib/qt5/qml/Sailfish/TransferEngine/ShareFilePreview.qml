/****************************************************************************************
**
** Copyright (c) 2021 Open Mobile Platform LLC
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/
import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Gallery 1.0
import Sailfish.FileManager 1.0
import Sailfish.TransferEngine 1.0
import Nemo.Thumbnailer 1.0
import Nemo.FileManager 1.0

Item {
    id: root

    property var shareAction
    property alias sailfishTransfer: sailfishTransfer
    property alias remoteDirName: targetFolderLabel.text
    property alias remoteDirReadOnly: targetFolderLabel.readOnly
    property alias fileInfo: fileInfo

    property alias imageScaleVisible: scaleComboBox.visible
    property alias descriptionVisible: descriptionTextField.visible
    property alias descriptionPlaceholderText: descriptionTextField.placeholderText
    property alias metaDataSwitchVisible: metaDataSwitch.visible
    property bool metadataStripped

    property real _scalePercent: 1.0
    readonly property bool _isPortrait: __silica_applicationwindow_instance.orientation === Qt.PortraitOrientation
                                        || __silica_applicationwindow_instance.orientation === Qt.InvertedPortraitOrientation

    width: parent.width
    height: secondarySettings.y + secondarySettings.height

    Component.onCompleted: {
        sailfishTransfer.loadConfiguration(shareAction.toConfiguration())
    }

    FileInfo {
        id: fileInfo
        url: sailfishTransfer.source
    }

    SailfishTransfer {
        id: sailfishTransfer
    }

    Thumbnail {
        id: preview

        x: Theme.paddingLarge
        width: root._isPortrait ? (root.width - Theme.paddingLarge*2) : (root.width / 2.5)
        height: root._isPortrait ? (Screen.height / 4.5) : mainSettings.height
        sourceSize.width: width
        sourceSize.height: height

        visible: status === Thumbnail.Ready || status === Thumbnail.Loading
        fillMode: Thumbnail.PreserveAspectCrop
        clip: true
        mimeType: fileInfo.mimeType
        source: sailfishTransfer.source
    }

    Column {
        id: mainSettings

        anchors {
            top: root._isPortrait && preview.visible ? preview.bottom : preview.top
            left: root._isPortrait || !preview.visible ? parent.left : preview.right
            right: parent.right
        }
        topPadding: root._isPortrait ? Theme.paddingMedium : 0

        Label {
            id: nameField

            x: root._isPortrait ? Theme.horizontalPageMargin : Theme.paddingLarge
            width: parent.width - x - Theme.horizontalPageMargin
            text: sailfishTransfer.content.name || fileInfo.fileName
            color: Theme.highlightColor
        }

        Label {
            x: root._isPortrait ? Theme.horizontalPageMargin : Theme.paddingLarge
            width: parent.width - x - Theme.horizontalPageMargin
            height: implicitHeight + Theme.paddingMedium
            text: {
                var fileSize = fileInfo.fileName.length > 0
                        ? fileInfo.size
                        : (!!sailfishTransfer.content.data ? sailfishTransfer.content.data.length || 0 : 0)
                return fileSize > 0 ? Format.formatFileSize(fileSize) : ""
            }
            visible: text.length > 0
            truncationMode: TruncationMode.Fade
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeSmall
        }

        TextField {
            id: descriptionTextField

            width: parent.width

            //: Image description
            //% "Description"
            placeholderText: qsTrId("sailfishshare-la-description")
            label: placeholderText

            EnterKey.iconSource: "image://theme/icon-m-enter-close"
            EnterKey.onClicked: root.focus = true
        }

        TextField {
            id: targetFolderLabel

            width: parent.width
            visible: targetFolderLabel.text.length > 0 || !targetFolderLabel.readOnly
            readOnly: true
            color: readOnly ? Theme.highlightColor : Theme.primaryColor
            //% "Destination folder"
            label: qsTrId("sailfishshare-la-destination_folder")
            placeholderText: label
        }

        Item {
            x: root._isPortrait ? Theme.horizontalPageMargin : Theme.paddingLarge
            width: parent.width - x - Theme.horizontalPageMargin
            height: Theme.itemSizeMedium
            visible: accountMainLabel.text.length > 0

            Image {
                id: icon

                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
                source: sailfishTransfer.transferMethodInfo.methodIcon
                sourceSize.width: Theme.iconSizeMedium
                sourceSize.height: Theme.iconSizeMedium
            }

            Label {
                id: accountMainLabel

                anchors {
                    left: icon.right
                    leftMargin: Theme.paddingMedium
                    right: parent.right
                    verticalCenter: icon.verticalCenter
                    verticalCenterOffset: accountSubLabel.text.length > 0 ? -accountSubLabel.height/2 : 0
                }
                text: sailfishTransfer.transferMethodInfo.subtitle
                      || sailfishTransfer.transferMethodInfo.displayName
                truncationMode: TruncationMode.Fade
                color: Theme.highlightColor
            }

            Label {
                id: accountSubLabel

                anchors {
                    top: accountMainLabel.bottom
                    left: icon.right
                    leftMargin: Theme.paddingMedium
                    right: parent.right
                }
                text: sailfishTransfer.transferMethodInfo.subtitle
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
            }
        }
    }

    Column {
        id: secondarySettings

        y: root._isPortrait
           ? mainSettings.y + mainSettings.height
           : Math.max(preview.y + preview.height, mainSettings.y + mainSettings.height)
        width: parent.width

        ComboBox {
            id: scaleComboBox

            width: parent.width
            currentIndex: 3

            //: Image scale
            //% "Scale image"
            label: qsTrId("sailfishshare-la-scale_image")

            menu: ContextMenu {
                x: 0
                width: scaleComboBox.width

                //: Image scale is 25%
                //% "25 %"
                MenuItem { text: qsTrId("sailfishshare-va-25_percent"); onClicked: root._scalePercent = 0.25 }
                //: Image scale is 50%
                //% "50 %"
                MenuItem { text: qsTrId("sailfishshare-va-50_percent"); onClicked: root._scalePercent = 0.5 }
                //: Image scale is 75%
                //% "75 %"
                MenuItem { text: qsTrId("sailfishshare-va-75_percent"); onClicked: root._scalePercent = 0.75  }
                //: Image scale is original
                //% "original"
                MenuItem { text: qsTrId("sailfishshare-va-original"); onClicked: root._scalePercent = 1 }
            }
        }

        TextSwitch {
            id: metaDataSwitch

            //: Include image metadata
            //% "Include metadata"
            text: qsTrId("sailfishshare-me-include_metadata")
            checked: !root.metadataStripped
        }

        SystemDialogIconButton {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width / 2
            iconSource: "image://theme/icon-m-share"
            bottomPadding: Theme.paddingLarge
            _showPress: false

            //% "Share"
            text: qsTrId("sailfishshare-la-share")

            onClicked: {
                sailfishTransfer.metadataStripped = !metaDataSwitch.checked
                sailfishTransfer.userData = {
                    "description": descriptionTextField.text,
                    "accountId": sailfishTransfer.transferMethodInfo.accountId,
                    "scalePercent": root._scalePercent,
                    "remoteDirName": root.remoteDirName,
                }
                sailfishTransfer.start()
                shareAction.done()
            }
        }
    }
}
