import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Weather 1.0
import Nemo.Configuration 1.0

ListItem {
    id: weatherBanner

    property alias weather: savedWeathersModel.currentWeather
    property alias autoRefresh: savedWeathersModel.autoRefresh
    property alias active: weatherModel.active
    property bool hourly: forecastMode.value === "hourly"
    property bool expanded: true
    readonly property QtObject forecastModel: hourly ? (hourlyForecastLoader.item ? hourlyForecastLoader.item.model : null)
                                                     : (dailyForecastLoader.item ? dailyForecastLoader.item.model : null)
    readonly property bool loading: forecastModel && forecastModel.status === Weather.Loading
    readonly property bool _error: forecastModel && forecastModel.status === Weather.Error
    readonly property bool _unauthorized: forecastModel && forecastModel.status === Weather.Unauthorized
    readonly property int _forecastCount: forecastModel ? forecastModel.count : 0

    _backgroundColor: "transparent"
    onActiveChanged: if (!active) save()
    onHourlyChanged: forecastMode.value = hourly ? "hourly" : "daily"

    function reload(userRequested) {
        weatherModel.reload(userRequested)
        forecastModel.reload(userRequested)
    }

    function save() {
        savedWeathersModel.save()
    }

    onClicked: {
        if (!expanded) {
            expanded = true
        } else if (!_error && !_unauthorized) {
            hourly = !hourly
        }

        if (!_unauthorized) {
            weatherModel.attemptReload(true)
            forecastModel.attemptReload(true)
        }
    }

    visible: enabled
    contentHeight: enabled ? column.height : 0
    enabled: weather && weather.populated

    menu: Component {
        ContextMenu {
            MenuLabel {
                //% "Updated %1"
                text: forecastModel ? qsTrId("weather-la-updated_time").arg(
                                          Format.formatDate(forecastModel.timestamp, Formatter.Timepoint))
                                    : ""
                visible: !_error && !_unauthorized && !loading
            }

            MenuItem {
                //% "Open app"
                text: qsTrId("weather-la-open_app")
                onClicked: WeatherLauncher.launch()
            }
            MenuItem {
                visible: !_unauthorized
                //% "Reload"
                text: qsTrId("weather-la-reload")
                onClicked: reload(true)
            }
        }
    }

    Column {
        id: column
        width: parent.width
        Row {
            id: row

            property int margin: (column.width - image.width - Theme.paddingMedium - temperatureLabel.width
                                  - Theme.paddingSmall - cityLabel.width)/2

            x: margin
            width: parent.width - x
            height: Theme.itemSizeSmall

            Image {
                id: image
                width: height
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                source: weather && weather.weatherType.length > 0 ? "image://theme/icon-l-weather-" + weather.weatherType
                                                                    + (highlighted ? ("?" + Theme.highlightColor) : "")
                                                                  : ""
            }

            Item {
                width: Theme.paddingMedium
                height: 1
            }

            Label {
                id: temperatureLabel
                text: weather ? TemperatureConverter.format(weather.temperature) : ""
                font.pixelSize: Theme.fontSizeExtraLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: Theme.paddingSmall
                height: 1
            }

            Label {
                id: cityLabel
                text: weather ? weather.city : ""
                color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font {
                    pixelSize: Theme.fontSizeSmall
                    family: Theme.fontFamilyHeading
                }
                anchors.baseline: temperatureLabel.baseline
                truncationMode: TruncationMode.Fade
                width: Math.min(implicitWidth,
                                column.width - image.width - Theme.paddingMedium - Theme.paddingSmall
                                - temperatureLabel.width - expandButton.width - Theme.horizontalPageMargin)
            }

            Item {
                height: 1
                width: parent.margin - expandButton.width - Theme.horizontalPageMargin + Theme.paddingLarge
            }

            IconButton {
                id: expandButton

                height: Math.max(parent.height, Theme.itemSizeSmall)
                width: icon.width + 2*Theme.paddingLarge
                onClicked: expanded = !expanded
                icon {
                    transformOrigin: Item.Center
                    source: "image://theme/icon-s-arrow"
                    rotation: expanded ? 180 : 0
                }
                Behavior on icon.rotation { RotationAnimator { duration: 200 }}
            }
        }
        Column {
            width: parent.width
            opacity: expanded ? 1.0 : 0.0

            height: expanded ? implicitHeight : 0
            Behavior on opacity { FadeAnimator {} }
            Behavior on height {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }

            Item {
                width: parent.width
                height: Math.max(hourlyForecastLoader.height, dailyForecastLoader.height)
                Loader {
                    id: dailyForecastLoader
                    width: parent.width
                    active: !weatherBanner.hourly && expanded
                    anchors.verticalCenter: parent.verticalCenter
                    onActiveChanged: if (active) active = active // remove binding

                    sourceComponent: WeatherForecastList {
                        id: dailyForecastList

                        columnCount: model.visibleCount
                        active: !weatherBanner.hourly
                        model: WeatherForecastModel {
                            active: weatherBanner.active && !weatherBanner.hourly
                            weather: weatherBanner.weather
                            timestamp: weatherModel.timestamp
                        }

                        delegate: Item {
                            width: dailyForecastList.itemWidth
                            height: dailyForecastList.height
                            DailyForecastItem {
                                highlighted: weatherBanner.highlighted
                                onHeightChanged: if (model.index == 0) dailyForecastList.itemHeight = height
                            }
                        }
                    }
                }

                Loader {
                    id: hourlyForecastLoader
                    width: parent.width
                    active: weatherBanner.hourly && expanded
                    anchors.verticalCenter: parent.verticalCenter
                    onActiveChanged: if (active) active = active // remove binding

                    sourceComponent: WeatherForecastList {
                        id: hourlyForecastList

                        property int hourMode: timeFormatConfig.value === "24" ? DateTime.TwentyFourHours
                                                                               : DateTime.TwelveHours
                        active: weatherBanner.hourly
                        columnCount: model.visibleCount

                        FontMetrics {
                            id: fontMetrics
                            font.pixelSize: Theme.fontSizeMedium // align with temperature label in HourlyForecastItem
                        }

                        Item {
                            y: fontMetrics.height

                            visible: hourlyForecastList.model.count > 0
                            width: hourlyForecastList.width - hourlyForecastList.itemWidth/2
                            height: temperatureGraph.height
                            anchors.horizontalCenter: parent.horizontalCenter
                            clip: true

                            LineGraph {
                                id: temperatureGraph

                                function update() {
                                    var array = []
                                    var model = hourlyForecastList.model

                                    array[0] = 2 * model.get(0).relativeTemperature - model.get(1).relativeTemperature
                                    for (var i = 0; i < model.visibleCount; i++) {
                                        array[i + 1] = model.get(i).relativeTemperature
                                    }
                                    array[model.visibleCount + 1] = model.get(model.visibleCount).relativeTemperature
                                    values = array
                                }

                                width: hourlyForecastList.width + hourlyForecastList.itemWidth
                                anchors.horizontalCenter: parent.horizontalCenter
                                height: Theme.itemSizeMedium/2
                                lineWidth: Theme.paddingSmall/3
                                color: Theme.highlightColor
                            }
                        }

                        model: WeatherForecastModel {
                            hourly: true
                            active: weatherBanner.active && weatherBanner.hourly
                            weather: weatherBanner.weather
                            timestamp: weatherModel.timestamp
                            onStatusChanged: if (status === Weather.Ready) temperatureGraph.update()
                        }

                        delegate: Item {
                            width: hourlyForecastList.itemWidth
                            height: hourlyForecastList.height
                            HourlyForecastItem {
                                hourMode: hourlyForecastList.hourMode
                                highlighted: weatherBanner.highlighted
                                onHeightChanged: if (model.index == 0) hourlyForecastList.itemHeight = height
                            }
                        }
                    }
                }

                BusyIndicator {
                    size: Screen.sizeCategory >= Screen.Large ? BusyIndicatorSize.Large : BusyIndicatorSize.Medium
                    anchors.centerIn: parent
                    running: weatherBanner.loading && forecastModel.count === 0
                }

                Column {
                    width: parent.width
                    spacing: Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter

                    opacity: (_error || _unauthorized) && _forecastCount === 0 ? 1 : 0
                    Behavior on opacity { FadeAnimator {} }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (_error) {
                                //% "No network"
                                return qsTrId("weather-la-no_network")
                            }

                            //% "Invalid authentication credentials"
                            return qsTrId("weather-la-unauthorized")
                        }
                        font.pixelSize: _error ? Theme.fontSizeLarge : Theme.fontSizeMedium
                    }
                    Label {
                        visible: _error
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor

                        //% "Tap to retry"
                        text: qsTrId("weather-la-tap_to_retry")
                    }
                }
            }

            MouseArea {
                id: footer

                property bool down: pressed && containsMouse

                onClicked: Qt.openUrlExternally("http://foreca.mobi/spot.php?l=" + savedWeathersModel.currentWeather.locationId)

                width: footerRow.width
                height: footerRow.height + Theme.paddingSmall
                anchors { right: parent.right; rightMargin: Theme.horizontalPageMargin }
                enabled: savedWeathersModel.currentWeather && savedWeathersModel.currentWeather.populated && !_error && expanded

                Row {
                    id: footerRow

                    BusyIndicator {
                        size: BusyIndicatorSize.Small
                        anchors.verticalCenter: parent.verticalCenter
                        running: minimumTimeout.running || (weatherBanner.loading && forecastModel.count > 0)
                        onRunningChanged: minimumTimeout.restart()
                        Timer {
                            id: minimumTimeout
                            interval: 400
                        }
                    }
                    Item {
                        height: 1
                        width: Theme.paddingMedium
                    }

                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "image://theme/graphic-foreca-small?"
                                + (highlighted || footer.down ? Theme.highlightColor : Theme.primaryColor)
                    }
                    Label {
                        //: Indicates when the shown forecast information was updated
                        //: Displayed right after small Foreca logo, i.e. "FORECA, updated 12:59, 1.3.2020"
                        //% ", updated %1"
                        text: forecastModel ? qsTrId("weather-la-comma_updated_time")
                                              .arg(Format.formatDate(forecastModel.timestamp, Format.Timepoint))
                                            : ""
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeExtraSmall
                        highlighted: weatherBanner.highlighted || footer.down

                        visible: _error && _forecastCount > 0
                    }
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                horizontalAlignment: Text.AlignRight
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap

                //% "No network, tap to retry"
                text: qsTrId("weather-la-no_network_tap_to_retry")

                color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                opacity: enabled ? 1 : 0
                height: enabled ? implicitHeight : 0
                enabled: _error && _forecastCount > 0
                Behavior on opacity { FadeAnimator {} }
                Behavior on height {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    SavedWeathersModel {
        id: savedWeathersModel
        autoRefresh: true
    }

    WeatherModel {
        id: weatherModel
        weather: savedWeathersModel.currentWeather
        savedWeathers: savedWeathersModel
    }

    ConfigurationValue {
        id: forecastMode
        key: "/sailfish/weather/forecast_mode"
        defaultValue: "hourly"
    }

    ConfigurationValue {
        id: timeFormatConfig
        key: "/sailfish/i18n/lc_timeformat24h"
    }
}
