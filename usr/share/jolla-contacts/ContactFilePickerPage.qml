import QtQuick 2.0
import Sailfish.Silica 1.0
import QtDocGallery 5.0

Page {
    id: root

    signal fileSelected(url fileUrl)

    DocumentGalleryModel {
        id: fileModel
        properties: ["url", "fileName"]
        sortProperties: ["+fileName"]
        rootType: DocumentGallery.File
        filter: GalleryEqualsFilter { property: "fileExtension"; value: "vcf" }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: Math.max(height, header.height + fileList.height)

        PageHeader {
            id: header
            //% "Contact file"
            title: qsTrId("contacts_settings-he-contact_file")
        }

        ColumnView {
            id: fileList
            width: parent.width
            anchors.top: header.bottom

            model: fileModel

            itemHeight: Theme.itemSizeSmall

            delegate: BackgroundItem {
                width: parent.width
                Label {
                    anchors {
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    truncationMode: TruncationMode.Fade
                    text: fileName
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                onClicked: {
                    root.fileSelected(url)
                }
            }
        }

        ViewPlaceholder {
            enabled: fileModel.count == 0 && (fileModel.status === DocumentGalleryModel.Finished || fileModel.status === DocumentGalleryModel.Idle)

            //% "No contact files found"
            text: qsTrId("contacts_settings-la-no_contact_files_found")

            //: Shown when user does not have any vcard files on the device
            //% "Copy some vcard files to device"
            hintText: qsTrId("contacts_settings-la-copy_contact_files_to_device")
        }

        VerticalScrollDecorator {}
    }
}
