import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.FileManager 1.0
import QtDocGallery 5.0
import Sailfish.Gallery.private 1.0
import "private"

Page {
    id: page

    property url source
    property bool isImage: true
    property alias itemType: itemModel.rootType

    allowedOrientations: Orientation.All

    // https://developer.gnome.org/ontology/stable/nmm-Flash.html
    property var flashValues: {
        'http://tracker.api.gnome.org/ontology/v3/nmm#flash-on':
        //% "Did fire"
        qsTrId("components_gallery-value-flash-on"),
        'http://tracker.api.gnome.org/ontology/v3/nmm#flash-off':
        //% "Did not fire"
        qsTrId("components_gallery-value-flash-off")
    }

    // https://developer.gnome.org/ontology/stable/nmm-MeteringMode.html
    property var meteringModeValues: {
        'http://tracker.api.gnome.org/ontology/v3/nmm#metering-mode-other':
        //% "Other"
        qsTrId("components_gallery-value-metering-mode-other"),
        'http://tracker.api.gnome.org/ontology/v3/nmm#metering-mode-partial':
        //% "Partial"
        qsTrId("components_gallery-value-metring-mode-partial"),
        'http://tracker.api.gnome.org/ontology/v3/nmm#metering-mode-pattern':
        //% "Pattern"
        qsTrId("components_gallery-value-metering-mode-pattern"),
        'http://tracker.api.gnome.org/ontology/v3/nmm#metering-mode-multispot':
        //% "Multispot"
        qsTrId("components_gallery-value-metering-mode-multispot"),
        'http://tracker.api.gnome.org/ontology/v3/nmm#metering-mode-spot':
        //% "Spot"
        qsTrId("components_gallery-value-metering-mode-spot"),
        'http://tracker.api.gnome.org/ontology/v3/nmm#metering-mode-center-weighted-average':
        //% "Center Weighted Average"
        qsTrId("components_gallery-value-metering-mode-center-weighted-average"),
        'http://tracker.api.gnome.org/ontology/v3/nmm#metering-mode-average':
        //% "Average"
        qsTrId("components_gallery-value-metering-mode-average")
    }

    // https://developer.gnome.org/ontology/stable/nmm-WhiteBalance.html
    property var whiteBalanceValues: {
        'http://tracker.api.gnome.org/ontology/v3/nmm#white-balance-manual':
        //% "Manual"
        qsTrId("components_gallery-value-white-balance-manual"),
        'http://tracker.api.gnome.org/ontology/v3/nmm#white-balance-auto':
        //% "Auto"
        qsTrId("components_gallery-value-white-balance-auto")
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: details.height

        Column {
            id: details

            width: parent.width

            Repeater {
                model: DocumentGalleryModel {
                    id: itemModel

                    rootType: page.isImage ? DocumentGallery.Image : DocumentGallery.Video
                    properties: [ 'filePath', 'fileSize', 'mimeType',
                                  // Image & Video common
                                  'width', 'height',
                                  // Media
                                  'duration',
                                  // Photo
                                  'dateTaken', 'cameraManufacturer', 'cameraModel',
                                  // exposureProgram is not supported by Tracker thus not enabled.
                                  // https://github.com/qtproject/qtdocgallery/blob/0b9ca223d4d5539ff09ce49a841fec4c24077830/src/gallery/qdocumentgallery.cpp#L799
                                  'exposureTime',
                                  'fNumber', 'flashEnabled', 'focalLength', 'meteringMode', 'whiteBalance',
                                  'latitude', 'longitude', 'altitude',
                                  'description', 'copyright', 'author'
                                ]
                    filter: GalleryEqualsFilter {
                        id: filter

                        property: 'url'
                        value: page.source
                    }
                }
                delegate: model.rootType === DocumentGallery.Image ? imageDetails : videoDetails
            }

            Component {
                id: imageDetails

                ImageDetailsItem {
                    filePathDetail.value: model.filePath
                    fileSizeDetail.value: Format.formatFileSize(model.fileSize)
                    typeDetail.value: model.mimeType
                    sizeDetail.value: formatDimensions(model.width, model.height)

                    dateTakenDetail.value: model.dateTaken != ""
                            ? Format.formatDate(model.dateTaken, Format.Timepoint)
                            : ""
                    cameraManufacturerDetail.value: model.cameraManufacturer
                    cameraModelDetail.value: model.cameraModel
                    exposureTimeDetail.value: model.exposureTime
                    fNumberDetail.value: model.fNumber != ""
                            ? formatFNumber(model.fNumber)
                            : ""
                    flashEnabledDetail.value: model.flashEnabled != ""
                            ? flashValues[model.flashEnabled]
                            : ""
                    focalLengthDetail.value: model.focalLength != ""
                            ? formatFocalLength(model.focalLength)
                            : ""
                    meteringModeDetail.value: model.meteringMode != ""
                            ? meteringModeValues[model.meteringMode]
                            : ""
                    whiteBalanceDetail.value: model.whiteBalance != ""
                              ? whiteBalanceValues[model.whiteBalance]
                              : ""
                    gpsDetail.value: model.latitude != ""
                            ? formatGpsCoordinates(model.latitude,
                                                   model.longitude,
                                                   model.altitude)
                            : ""
                    descriptionDetail.value: model.description
                    copyrightDetail.value: model.copyright
                    authorDetail.value: model.author
                }
            }
            Component {
                id: videoDetails

                ImageDetailsItem {
                    filePathDetail.value: model.filePath
                    fileSizeDetail.value: Format.formatFileSize(model.fileSize)
                    typeDetail.value: model.mimeType
                    sizeDetail.value: formatDimensions(model.width, model.height)

                    durationDetail.value: Format.formatDuration(model.duration, Formatter.DurationLong)

                }
            }

            // Limited fallback for when tracker has no entry for a file.
            Loader {
                width: parent.width
                active: itemModel.status === DocumentGalleryModel.Error
                        || (itemModel.status === DocumentGalleryModel.Error && itemModel.count == 0)

                sourceComponent: ImageDetailsItem {
                    filePathDetail.value: fileInfo.file
                    fileSizeDetail.value: Format.formatFileSize(fileInfo.size)
                    typeDetail.value: fileInfo.mimeType
                    sizeDetail.value: metadata.valid
                                ? formatDimensions(metadata.width, metadata.height)
                                : ""

                    FileInfo {
                        id: fileInfo

                        url: page.source
                    }

                    ImageMetadata {
                        id: metadata

                        source: page.source
                    }
                }
            }

        }

        VerticalScrollDecorator { }
    }
}
