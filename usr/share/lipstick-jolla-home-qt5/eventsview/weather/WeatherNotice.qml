/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Aaron McCarthy <aaron.mccarthy@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

BackgroundItem {
    width: parent.width
    height: heading.height + description.height + Theme.paddingSmall
    
    onClicked: weatherService.call("newLocation", [])
    
    WeatherIcon {
        id: icon
        
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            verticalCenter: heading.bottom
        }
    }
    Text {
        id: heading
        
        anchors {
            left: icon.right
            leftMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
        
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
        font {
            pixelSize: Theme.fontSizeLarge
            family: Theme.fontFamilyHeading
        }
        wrapMode: Text.Wrap
        //% "Set your location"
        text: qsTrId("lipstick-jolla-home-la-weather_set_your_location")
    }
    Text {
        id: description
        
        anchors {
            top: heading.bottom
            left: heading.left
            right: heading.right
        }
        
        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        font {
            pixelSize: Theme.fontSizeExtraSmall
            family: Theme.fontFamily
        }
        
        //% "Tap here to set your location and see local weather in Events and Lock Screen"
        text: qsTrId("lipstick-jolla-home-la-weather_set_your_location_description")
        wrapMode: Text.Wrap
    }

    DBusInterface {
        id: weatherService

        service: "org.sailfishos.weather"
        path: "/org/sailfishos/weather"
        iface: "org.sailfishos.weather"
    }
}
