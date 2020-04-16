import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Weather 1.0
import QtQuick.XmlListModel 2.0

Page {
    id: page

    property bool error: locationsModel.status === XmlListModel.Error
    property bool loading: locationsModel.status === XmlListModel.Loading || loadingTimer.running
    objectName: "LocationSearchPage"

    Timer { id: loadingTimer; interval: 600 }
    LocationsModel {
        id: locationsModel
        onStatusChanged: if (status === XmlListModel.Loading) loadingTimer.restart()
        onFilterChanged: delayedFilter.restart()
    }
    SilicaListView {
        id: locationListView
        currentIndex: -1
        anchors.fill: parent
        model: locationsModel
        header: Column {
            width: parent.width
            PageHeader {
                //% "New location"
                title: qsTrId("weather-la-new_location")
            }
            SearchField {
                id: searchField

                //% "Search locations"
                placeholderText: qsTrId("weather-la-search_locations")
                onFocusChanged: if (focus) forceActiveFocus()
                width: parent.width
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: focus = false

                Binding {
                    target: locationsModel
                    property: "filter"
                    value: searchField.text.toLowerCase().trim()
                }
                Binding {
                    target: searchField
                    property: "focus"
                    value: true
                    when: page.status == PageStatus.Active && locationListView.atYBeginning
                }
            }
        }
        BusyIndicator {
            running: !error && loading && locationsModel.filter.length > 0 && locationsModel.count === 0
            anchors.horizontalCenter: parent.horizontalCenter
            y: placeHolder.y + Math.round(height/2)
            parent: placeHolder.parent
            size: BusyIndicatorSize.Large
        }
        ViewPlaceholder {
            id: placeHolder
            text: {
                if (error) {
                    //% "Loading failed"
                    return qsTrId("weather-la-loading_failed")
                } else if (locationsModel.filter.length === 0) {
                    //: Placeholder displayed when user hasn't yet typed a search string
                    //% "Search and select new location"
                    return qsTrId("weather-la-search_and_select_location")
                } else if (!loading && !delayedFilter.running && locationListView.count == 0) {
                    if (locationsModel.filter.length < 3) {
                        //% "Could not find the location. Type at least three characters to perform a partial word search."
                        return qsTrId("weather-la-search_three_characters_required")
                    } else {
                        //% "Sorry, we couldn't find anything"
                        return qsTrId("weather-la-could_not_find_anything")
                    }
                }
                return ""
            }

            // Suppress error label flicker when filter has changed but model loading state hasn't yet had time to update
            Timer {
                id: delayedFilter
                interval: 1
            }

            enabled: error || (locationListView.count == 0 && !loading) || locationsModel.filter.length < 1

            y: locationListView.originY + Math.round(parent.height/14)
               + (locationListView.headerItem ? locationListView.headerItem.height : 0)
            Button {
                //% "Try again"
                text: error ? qsTrId("weather-la-try_again")
                              //% "Save current"
                            : qsTrId("weather-bt-save_current")
                visible: error
                onClicked: locationsModel.reload()
                anchors {
                    top: parent.bottom
                    topMargin: Theme.paddingMedium
                    horizontalCenter: parent.horizontalCenter
                }
            }
        }
        delegate: BackgroundItem {
            id: searchResultItem
            height: Theme.itemSizeMedium
            onClicked: {
                var location = {
                    "locationId": model.locationId,
                    "city": model.city,
                    "state": model.state,
                    "country": model.country
                }
                if (!savedWeathersModel.currentWeather
                        || savedWeathersModel.currentWeather.status === Weather.Error) {
                    savedWeathersModel.setCurrentWeather(location)
                } else {
                    savedWeathersModel.addLocation(location)
                }

                pageStack.pop()
            }
            ListView.onAdd: AddAnimation { target: searchResultItem; from: 0; to: 1 }
            ListView.onRemove: FadeAnimation { target: searchResultItem; from: 1; to: 0 }
            Column {
                anchors {
                    left: parent.left
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin - Theme.paddingMedium
                    leftMargin: Theme.itemSizeSmall + Theme.horizontalPageMargin - Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
                Label {
                    width: parent.width
                    textFormat: Text.StyledText
                    text: Theme.highlightText(model.city, locationsModel.filter, Theme.highlightColor)
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                    truncationMode: TruncationMode.Fade
                }
                Label {
                    width: parent.width
                    textFormat: Text.StyledText
                    text: Theme.highlightText((model.state && model.state.length > 0 ? model.state + ", " : "")
                                              + model.country, locationsModel.filter, Theme.highlightColor)
                    color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                }
            }
        }
        VerticalScrollDecorator {}
    }
}
