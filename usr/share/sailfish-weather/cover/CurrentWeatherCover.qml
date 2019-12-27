import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Weather 1.0

Item {
    WeatherCoverItem {
        x: Theme.paddingLarge
        width: parent.width - 2*x
        topPadding: Theme.paddingLarge
        text: weather.status === Weather.Error ? model.city : TemperatureConverter.format(weather.temperature) + " " + weather.city
        //% "Loading failed"
        description: weather.status === Weather.Error ? qsTrId("weather-la-loading_failed") : weather.description
    }
    WeatherImage {
        id: weatherImage

        height: width
        width: parent.width - Theme.paddingLarge
        sourceSize.width: width
        sourceSize.height: width
        weatherType: weather ? weather.weatherType : ""
        anchors {
            centerIn: parent
            verticalCenterOffset: Theme.paddingSmall
        }
    }
    Image {
        scale: 0.5
        opacity: 0.5
        anchors {
            bottom: parent.bottom
            bottomMargin: Math.round(Theme.paddingSmall/2)
            horizontalCenter: parent.horizontalCenter
        }
        source: "image://theme/graphic-foreca-small"
    }

}
