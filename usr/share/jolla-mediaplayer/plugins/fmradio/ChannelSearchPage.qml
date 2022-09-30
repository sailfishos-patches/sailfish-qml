import QtQuick 2.0
import QtMultimedia 5.0
import Sailfish.Silica 1.0
import com.jolla.mediaplayer.radio 1.0

Page {
    property Radio radio
    property var availableStations
    property var bookmarks

    onStatusChanged: {
        if (status == PageStatus.Inactive) {
            radio.cancelSearchAll()
        } else if (status == PageStatus.Activating && availableStations.length == 0) {
            radio.searchAll()
        }
    }

    FrequencyFormatter {
        id: formatter
    }

    SilicaListView {
        id: channelList

        header: PageHeader {
            // translation on push up menu
            title: qsTrId("jolla-mediaplayer-radio-available_channels")
        }

        anchors.fill: parent
        model: availableStations
        delegate: ListItem {
            id: channelItem

            menu: contextMenu
            onClicked: {
                radio.frequency = modelData
                radio.startPlay()
            }

            Label {
                id: frequencyText

                anchors.centerIn: parent
                font.pixelSize: Theme.fontSizeLarge
                color: channelItem.highlighted || radio.frequency == modelData ? Theme.highlightColor
                                                                               : Theme.primaryColor
                text: formatter.formatMegahertz(modelData / 1000000)
            }
            Label {
                anchors.left: frequencyText.right
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingMedium
                anchors.baseline: frequencyText.baseline
                font.pixelSize: Theme.fontSizeMedium
                truncationMode: TruncationMode.Fade
                color: channelItem.highlighted || radio.frequency == modelData ? Theme.highlightColor
                                                                               : Theme.secondaryColor
                text: {
                    var index = bookmarks.findByFrequency(modelData)
                    if (index >= 0) {
                        return bookmarks.get(index, RadioBookmarks.NameRole)
                    } else if (modelData == radio.frequency) {
                        return radio.radioData.stationName.trim()
                    } else {
                        return ""
                    }
                }
            }
            Component {
                id: contextMenu

                ContextMenu {
                    MenuItem {
                        //% "Add to favorites"
                        text: qsTrId("jolla-mediaplayer-radio-add_to_favorites")
                        onClicked: {
                            bookmarks.addStation(radio.radioData.stationName.trim(),
                                                 radio.radioData.stationId.trim(),
                                                 radio.frequency)
                            channelList.update()
                        }
                    }
                }
            }
        }

        PullDownMenu {
            visible: !radio.searching

            MenuItem {
                //: Initiate channel search from pulley menu
                //% "Search"
                text: qsTrId("jolla-mediaplayer-radio-search")
                onClicked: radio.searchAll()
            }
        }

        Label {
            anchors.bottom: searchIndicator.top
            anchors.bottomMargin: Theme.paddingMedium
            anchors.horizontalCenter: searchIndicator.horizontalCenter
            color: Theme.highlightColor
            //% "Searching..."
            text: qsTrId("jolla-mediaplayer-radio-searching_stations")
            opacity: searchIndicator.opacity
            visible: searchIndicator.visible
        }

        BusyIndicator {
            id: searchIndicator

            anchors.centerIn: parent
            size: BusyIndicatorSize.Large
            running: radio.searching
        }
    }
}
