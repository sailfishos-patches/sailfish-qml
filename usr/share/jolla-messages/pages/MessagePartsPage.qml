import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import "conversation"

Page {
    id: messagePartsPage

    property QtObject modelData
    property int eventStatus

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        flickableDirection: Flickable.VerticalFlick
        contentHeight: contentColumn.height

        Column {
            id: contentColumn
            width: flickable.width

            PageHeader {
                //% "Multimedia Message"
                title: modelData.subject !== "" ? modelData.subject : qsTrId("messages-header_multimedia_message")
                wrapMode: Text.Wrap
            }

            LinkedText {
                id: body
                width: parent.width - (2 * Theme.horizontalPageMargin)
                x: Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                visible: plainText.length > 0
                plainText: modelData.freeText
            }

            Label {
                width: parent.width - (2 * Theme.horizontalPageMargin)
                x: Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: {
                    var statusText = mainWindow.eventStatusText(eventStatus, modelData.eventId)
                    if (statusText)
                        return statusText

                    var dateString = Format.formatDate(modelData.startTime, Formatter.DateMedium)
                    var timeString = Format.formatDate(modelData.startTime, Formatter.TimeValue)

                    //: This string is used to decide what order the date and time should appear together.
                    //: First argument is the date, second is the time.
                    //% "%1 %2"
                    return qsTrId("messages-la-date_time").arg(dateString).arg(timeString)
                }
            }

            Item {
                height: Theme.paddingLarge
                width: 1
                visible: body.visible
            }

            Grid {
                id: attachmentsGrid
                width: parent.width
                columns: isSingleImage() ? 1 : Math.floor(width / Theme.itemSizeLarge / 2)

                property int cellWidth: Math.floor(width / columns)

                function isSingleImage() {
                    var imageCount = 0
                    for (var i = 0; i < attachments.count && imageCount < 2; ++i) {
                        var delegate = attachments.itemAt(i)
                        if (delegate.isThumbnail) {
                            ++imageCount
                        } else if (delegate.isVCard) {
                            return false
                        }
                    }

                    return imageCount == 1
                }

                Repeater {
                    id: attachments
                    model: modelData.messageParts

                    MessagePartDelegate {
                        messagePart: modelData
                        time: messagePartsPage.modelData.startTime
                        size: attachmentsGrid.cellWidth
                        showFullImage: attachmentsGrid.columns == 1
                    }
                }
            }
        }

        VerticalScrollDecorator { }
    }
}
