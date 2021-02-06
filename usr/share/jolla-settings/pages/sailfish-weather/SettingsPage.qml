import QtQuick 2.0
import Sailfish.Silica 1.0
import org.sailfishos.weather.settings 1.0
import org.nemomobile.configuration 1.0
import com.jolla.settings 1.0

ApplicationSettings {
    id: root
    ConfigurationValue {
        id: temperatureUnitValue
        key: "/sailfish/weather/temperature_unit"
        defaultValue: "celsius"
    }

    ComboBox {
        //% "Temperature units"
        label: qsTrId("weather_settings-la-temperature_units")
        Component.onCompleted: {
            switch (temperatureUnitValue.value) {
            case "celsius":
                currentIndex = 0
                break
            case "fahrenheit":
                currentIndex = 1
                break
            default:
                console.log("WeatherSettings: Invalid temperature unit value", temperatureUnitValue.value)
                break
            }
        }

        menu: ContextMenu {
            MenuItem {
                //% "Celsius"
                text: qsTrId("weather_settings-me-celsius")
                onClicked: temperatureUnitValue.value = "celsius"
            }
            MenuItem {
                //% "Fahrenheit"
                text: qsTrId("weather_settings-me-fahrenheit")
                onClicked: temperatureUnitValue.value = "fahrenheit"
            }
        }
    }
}
