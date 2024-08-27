import QtQuick 2.0
import QtDocGallery 5.0
import Sailfish.Silica 1.0
import Sailfish.FileManager 1.0
import Nemo.FileManager 1.0

Page {
    DocumentGalleryModel {
        id: fileModel

        properties: ["url", "fileName"]
        sortProperties: ["+fileName"]
        rootType: DocumentGallery.File
        autoUpdate: true
        filter: GalleryFilterUnion {
            GalleryEqualsFilter { property: "fileExtension"; value: "rpm" }
            GalleryEqualsFilter { property: "fileExtension"; value: "apk" }
        }

    }

    SilicaListView {
        model: fileModel
        anchors.fill: parent
        header: PageHeader {
            //% "Install package"
            title: qsTrId("settings_packages-he-install_package")
        }

        delegate: BackgroundItem {
            height: fileItem.height

            onClicked: Qt.openUrlExternally(url)

            FileItem {
                id: fileItem
                fileName: model.fileName
                mimeType: fileInfo.mimeType
                size: fileInfo.size
                modified: fileInfo.lastModified

                FileInfo {
                    id: fileInfo
                    url: model.url
                }
            }
        }

        ViewPlaceholder {
            enabled: fileModel.count == 0 && (fileModel.status === DocumentGalleryModel.Finished || fileModel.status === DocumentGalleryModel.Idle)

            //% "No installable packages found"
            text: qsTrId("settings_packages-la-no_installable_packages_found")

            //% "Copy RPM or APK files to the internal memory or connected storage device"
            hintText: qsTrId("settings_packages-la-copy_package_files_to_device")
        }

        VerticalScrollDecorator {}
    }
}
