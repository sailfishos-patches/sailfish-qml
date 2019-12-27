/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
    height: Theme.itemSizeMedium

    // http://www.catb.org/gpsd/NMEA.html#_satellite_ids
    function getSatelliteSystem() {
        if (modelData.identifier >= 1 && modelData.identifier <= 32) {
            return "GPS"
        } else if (modelData.identifier >= 33 && modelData.identifier <= 54) {
            return "SBAS"
        } else if (modelData.identifier >= 65 && modelData.identifier <= 96) {
            return "GLONASS"
        } else if (modelData.identifier >= 193 && modelData.identifier <= 200) {
            return "QZSS"
        } else if (modelData.identifier >= 201 && modelData.identifier <= 235) {
            return "BeiDou"
        } else if (modelData.identifier >= 301 && modelData.identifier <= 330) {
            return "Galileo"
        }
    }

    Column {
        id: column

        x: Theme.paddingLarge
        width: Theme.itemSizeHuge

        Label {
            //% "Id: %1"
            text: qsTrId("csd-la-satellite_id").arg(modelData.identifier) + " " + getSatelliteSystem()
            font.pixelSize: Theme.fontSizeSmall
            color: modelData.inUse ? Theme.highlightColor : Theme.primaryColor
            width: parent.width
        }

        Label {
            //% "Azimuth: %1"
            text: qsTrId("csd-la-satellite_azimuth").arg(modelData.azimuth)
            font.pixelSize: Theme.fontSizeExtraSmall
            color: modelData.inUse ? Theme.highlightColor : Theme.primaryColor
            width: parent.width
            truncationMode: TruncationMode.Fade
        }

        Label {
            //% "Elevation: %1"
            text: qsTrId("csd-la-satellite_elevation").arg(modelData.elevation)
            font.pixelSize: Theme.fontSizeExtraSmall
            color: modelData.inUse ? Theme.highlightColor : Theme.primaryColor
            width: parent.width
            truncationMode: TruncationMode.Fade
        }
    }

    Rectangle {
        anchors {
            left: column.right
            leftMargin: Theme.paddingMedium
        }

        width: (parent.width - x) * modelData.strength / 100
        height: parent.height

        Text {
            anchors.centerIn: parent
            text: modelData.strength
            color: "white"
            visible: modelData.strength > 0
        }

        Behavior on width { NumberAnimation { duration: 500 } }

        color: modelData.inUse ? Theme.highlightColor : Theme.secondaryHighlightColor
    }
}

