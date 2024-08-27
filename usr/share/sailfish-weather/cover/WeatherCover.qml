import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Weather 1.0

CoverBackground {
    id: cover

    property QtObject weather: savedWeathersModel.currentWeather

    property bool current: true
    property bool ready: loaded && !error  && !unauthorized
    property bool loaded: weather
    property bool error: loaded && savedWeathersModel.currentWeather.status == Weather.Error
    property bool unauthorized: loaded && savedWeathersModel.currentWeather.status == Weather.Unauthorized

    function reload() {
        if (current) {
            if (savedWeathersModel.currentWeather && currentWeatherModel.updateAllowed()) {
                currentWeatherModel.reload()
            }
        } else if (savedWeathersModel.count > 1) {
            weatherApplication.reloadAllIfAllowed()
        }
    }

    onStatusChanged: if (status == Cover.Active) reload()
    onCurrentChanged: reload()

    CoverPlaceholder {
        visible: !ready
        icon.source: "image://theme/graphic-foreca-large"
        text: {
            if (!loaded) {
                //% "Select location to check weather"
                return qsTrId("weather-la-select_location_to_check_weather")
            } else if (error) {
                //% "Unable to connect, try again"
                return qsTrId("weather-la-unable_to_connect_try_again")
            } else if (unauthorized) {
                //% "Invalid authentication credentials"
                return qsTrId("weather-la-unauthorized")
            }

            return ""
        }
    }
    Loader {
        active: ready
        opacity: ready && current ? 1.0 : 0.0
        source: "CurrentWeatherCover.qml"
        Behavior on opacity { FadeAnimation {} }
        anchors.fill: parent
    }
    Loader {
        active: ready && savedWeathersModel.count > 0
        opacity: ready && !current ? 1.0 : 0.0
        source: "WeatherListCover.qml"
        Behavior on opacity { FadeAnimation {} }
        anchors.fill: parent
    }

    CoverActionList {
        enabled: !loaded
        CoverAction {
            iconSource: "image://theme/icon-cover-search"
            onTriggered: {
                var alreadyOpen = pageStack.currentPage && pageStack.currentPage.objectName === "LocationSearchPage"
                if (!alreadyOpen) {
                    pageStack.push(Qt.resolvedUrl("../pages/LocationSearchPage.qml"), undefined, PageStackAction.Immediate)
                }
                weatherApplication.activate()
            }
        }
    }
    CoverActionList {
        enabled: error
        CoverAction {
            iconSource: "image://theme/icon-cover-sync"
            onTriggered: {
                weatherApplication.reloadAll()
            }
        }
    }
    CoverActionList {
        enabled: ready && savedWeathersModel.count > 0
        CoverAction {
            iconSource: current ? "image://theme/icon-cover-previous"
                                : "image://theme/icon-cover-next"
            onTriggered: {
                current = !current
            }
        }
    }
    Connections {
        target: savedWeathersModel
        onCountChanged: if (savedWeathersModel.count === 0) current = true
    }
}
