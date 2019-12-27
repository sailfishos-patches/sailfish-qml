import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: detailsPage
    property QtObject model
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                //% "Details"
                title: qsTrId("jolla_gallery_extensions-he-details")
            }
            DetailItem {
                property var title: model && (model.title !== undefined ? model.title
                                                                        : model.text !== undefined ? model.text
                                                                                                   : undefined)

                //% "Title"
                label: qsTrId("jolla_gallery_extensions-la-title")
                //% "No title"
                value: title ? title : qsTrId("jolla_gallery_extensions-la-unnamed_photo")
                visible: title !== undefined
            }
            DetailItem {
                //% "Type"
                label: qsTrId("jolla_gallery_extensions-la-type")
                value: model ? model.mimeType : ""
                visible: value.length > 0
            }
            DetailItem {
                //% "Date Taken"
                label: qsTrId("jolla_gallery_extensions-la-date-taken")
                property var dateTaken: model && model.dateTaken
                value: dateTaken ? Format.formatDate(model.dateTaken, Format.Timepoint) : ""
                visible: value.length > 0
            }
            DetailItem {
                // TODO: Align date roles in the model side: Dropbox, OneDrive use DateTaken, VK Date
                //% "Date"
                label: qsTrId("jolla_gallery_extensions-la-date")
                property date date: model && new Date(model.date) // TODO: Fix inconsistency (date is integer)
                value: date ? Format.formatDate(date, Format.TimePoint) : ""
                visible: value.length > 0
            }
        }
        VerticalScrollDecorator {}
    }
}
