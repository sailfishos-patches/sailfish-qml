import QtQuick 2.0
import QtSensors 5.2
import Sailfish.Silica 1.0
import harbour.aida64.infopageloader 1.0

Item {
    property int page_id
    property int tabletLayout
    property var lvModel: infopageloader.loadPage(page_id, settings.getTempUnit + lcs.emptyString)

    SilicaListView {
        id: listView_Sensors
        model: lvModel
        anchors.fill: parent
        header: PageHeader {
            title: if (tabletLayout) return APP_NAME
                   else              return APP_NAME + " / " + infopageloader.getPageTitle(page_id) + lcs.emptyString
        }

        delegate: ListItem {
            id: delegate
            contentHeight: listCol.height
            enabled: false

            property int itemId: id

            Column {
                id: listCol
                x: horizPageMargin
                width: parent.width - 2 * x
                spacing: 0

/*                Item {
                  height: Theme.paddingSmall
                  width: 1
                } */

                Label {
                    id: fieldLabel
                    width: parent.width;
                    text: field + lcs.emptyString
                    color: {
                        if (itemId === InfoPageLoader.IIDENUM_DIV_DEVICE ||
                            itemId === InfoPageLoader.IIDENUM_DIV_DEVICE_1ST ||
                            itemId === InfoPageLoader.IIDENUM_NO_SENSOR) return Theme.highlightColor;
                        else return Theme.primaryColor;
                    }
                    horizontalAlignment: {
                        if (itemId === InfoPageLoader.IIDENUM_DIV_DEVICE ||
                            itemId === InfoPageLoader.IIDENUM_DIV_DEVICE_1ST ||
                            itemId === InfoPageLoader.IIDENUM_NO_SENSOR) return Text.AlignRight;
                        else return Text.AlignHCenter
                    }
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                }

                Label {
                    id: valueLabel
                    width: fieldLabel.width
                    text: value + lcs.emptyString
                    color: Theme.highlightColor
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                }

                Item {
                  height: Theme.paddingSmall
                  width: 1
                }
            }
        }

        VerticalScrollDecorator {}
    }

    Accelerometer {
        id: sensAccel
        active: false
        onReadingChanged: infopageloader.acceleroMeterReadingChanged(listView_Sensors.model,
                                                                     reading.x, reading.y, reading.z)
    }

//  Altimeter requires QtSensors 5.1

    Altimeter {
        id: sensAlti
        active: false
        onReadingChanged: infopageloader.altiMeterReadingChanged(listView_Sensors.model,
                                                                 reading.altitude)
    }

    AmbientLightSensor {
        id: sensAmbLight
        active: false
        onReadingChanged: {
            if (reading.lightLevel === AmbientLightReading.Undefined)
                infopageloader.ambientLightReadingChanged(listView_Sensors.model, "Undefined")
            else
            if (reading.lightLevel === AmbientLightReading.Dark)
                infopageloader.ambientLightReadingChanged(listView_Sensors.model, "Dark")
            else
            if (reading.lightLevel === AmbientLightReading.Twilight)
                infopageloader.ambientLightReadingChanged(listView_Sensors.model, "Twilight")
            else
            if (reading.lightLevel === AmbientLightReading.Light)
                infopageloader.ambientLightReadingChanged(listView_Sensors.model, "Light")
            else
            if (reading.lightLevel === AmbientLightReading.Bright)
                infopageloader.ambientLightReadingChanged(listView_Sensors.model, "Bright")
            else
            if (reading.lightLevel === AmbientLightReading.Sunny)
                infopageloader.ambientLightReadingChanged(listView_Sensors.model, "Sunny")
            else infopageloader.ambientLightReadingChanged(listView_Sensors.model, "Unknown")
        }
    }

//  AmbientTemperatureSensor requires QtSensors 5.1

    AmbientTemperatureSensor {
        id: sensAmbTemp
        active: false
        onReadingChanged: {
            onReadingChanged: infopageloader.ambientTempReadingChanged(listView_Sensors.model,
                                                                       reading.temperature)
        }
    }

    Compass {
        id: sensCompass
        active: false
        onReadingChanged: infopageloader.compassReadingChanged(listView_Sensors.model,
                                                               reading.azimuth)
    }

/*  DistanceSensor requires QtSensors 5.4

    DistanceSensor {
        id: sensDist
        active: false
        onReadingChanged: infopageloader.distSensorReadingChanged(listView_Sensors.model,
                                                                  reading.distance)
    } */

    Gyroscope {
        id: sensGyro
        active: false
        onReadingChanged: infopageloader.gyroscopeReadingChanged(listView_Sensors.model,
                                                                 reading.x, reading.y, reading.z)
    }

//  HolsterSensor requires QtSensors 5.1

    HolsterSensor {
        id: sensHolster
        active: false
        onReadingChanged: infopageloader.holsterSensorReadingChanged(listView_Sensors.model,
                                                                     reading.holstered)
    }

    IRProximitySensor {
        id: sensIRProx
        active: false
        onReadingChanged: infopageloader.irProxSensorReadingChanged(listView_Sensors.model,
                                                                    reading.reflectance)
    }

    LightSensor {
        id: sensLight
        active: false
        onReadingChanged: infopageloader.lightSensorReadingChanged(listView_Sensors.model,
                                                                   reading.illuminance)
    }

    Magnetometer {
        id: sensMagnet
        active: false
        onReadingChanged: infopageloader.magnetoMeterReadingChanged(listView_Sensors.model,
                                            reading.x * 1e6, reading.y * 1e6, reading.z * 1e6)
    }

    OrientationSensor {
        id: sensOrient
        active: false
        onReadingChanged: {
            if (reading.orientation === OrientationReading.Undefined)
                infopageloader.orientSensorReadingChanged(listView_Sensors.model, "Undefined")
            else
            if (reading.orientation === OrientationReading.TopUp)
                infopageloader.orientSensorReadingChanged(listView_Sensors.model, "TopUp")
            else
            if (reading.orientation === OrientationReading.TopDown)
                infopageloader.orientSensorReadingChanged(listView_Sensors.model, "TopDown")
            else
            if (reading.orientation === OrientationReading.LeftUp)
                infopageloader.orientSensorReadingChanged(listView_Sensors.model, "LeftUp")
            else
            if (reading.orientation === OrientationReading.RightUp)
                infopageloader.orientSensorReadingChanged(listView_Sensors.model, "RightUp")
            else
            if (reading.orientation === OrientationReading.FaceUp)
                infopageloader.orientSensorReadingChanged(listView_Sensors.model, "FaceUp")
            else
            if (reading.orientation === OrientationReading.FaceDown)
                infopageloader.orientSensorReadingChanged(listView_Sensors.model, "FaceDown")
            else infopageloader.orientSensorReadingChanged(listView_Sensors.model, "Unknown")
        }
    }

//  PressureSensor requires QtSensors 5.1

    PressureSensor {
        id: sensPressure
        active: false
        onReadingChanged: infopageloader.pressureSensorReadingChanged(listView_Sensors.model,
                              reading.pressure, reading.temperature)
    }

    ProximitySensor {
        id: sensProx
        active: false
        onReadingChanged: infopageloader.proxSensorReadingChanged(listView_Sensors.model,
                                                                  reading.near)
    }

    RotationSensor {
        id: sensRot
        active: false
        onReadingChanged: infopageloader.rotSensorReadingChanged(listView_Sensors.model,
                                                                 reading.x, reading.y, reading.z)
    }

    TiltSensor {
        id: sensTilt
        active: false
        onReadingChanged: infopageloader.tiltSensorReadingChanged(listView_Sensors.model,
                                                                  reading.xRotation, reading.yRotation)
    }

    Component.onCompleted: {
        sensAccel.active =
            sensAlti.active =
            sensAmbLight.active =
            sensAmbTemp.active =
            sensCompass.active =
//            sensDist.active =
            sensGyro.active =
            sensHolster.active =
            sensIRProx.active =
            sensLight.active =
            sensMagnet.active =
            sensOrient.active =
            sensPressure.active =
            sensProx.active =
            sensRot.active =
            sensTilt.active = true
    }
}
