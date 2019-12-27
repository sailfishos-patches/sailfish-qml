/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Nemo.Mce 1.0

SilicaItem {
    id: batteryStatusIndicator
    property alias icon: batteryStatusIndicatorImage.source
    property alias text: batteryStatusIndicatorText.text
    property alias color: batteryStatusIndicatorText.color
    property real totalHeight: height

    height: iconWidth
    width: batteryStatusIndicatorText.x+batteryStatusIndicatorText.width

    BatteryStatus {
        id: batteryStatus
    }
    McePowerSaveMode {
        id: mcePowerSaveMode
    }

    readonly property bool isCharging: batteryStatus.chargerStatus == BatteryStatus.Connected

    Item {
        id: chargeItem
        anchors.verticalCenter: parent.verticalCenter
        height: iconWidth
        width: iconWidth + chargeCableIcon.x
        clip: chargeCableAnim.running
        Image {
            id: chargeCableIcon
            source: "image://theme/icon-status-charge-cable" + iconSuffix
            anchors.verticalCenter: parent.verticalCenter
            width: iconWidth
            height: iconWidth
            sourceSize: iconSize
            visible: isCharging || chargeCableAnim.running
            x: isCharging ? 0 : -width
            Behavior on x { NumberAnimation { id: chargeCableAnim; duration: 500; easing.type: Easing.InOutQuad } }
        }
    }

    Image {
        id: batteryStatusIndicatorImage
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(chargeItem.width, Theme.paddingMedium)
        width: iconWidth
        height: iconWidth
        sourceSize: iconSize
        source: sourceValue

        readonly property bool baseNameEquals: sourceValue.indexOf(source) === 0 || source.toString().indexOf(sourceValue) === 0
        property string sourceValue: {
            var name = "battery"
            if (isCharging) {
                name = "charge"
            } else if (batteryStatus.status == BatteryStatus.Low || batteryStatus.status == BatteryStatus.Empty) {
                name = "battery-warning"
            } else if (mcePowerSaveMode.active) {
                name = "powersave"
            }
            return ["image://theme/icon-status-", name, iconSuffix].join("")
        }

        // delay updating state to coincide with cable animation touching the indicator
        onSourceValueChanged: statusChangeTimer.restart()

        Timer {
            id: statusChangeTimer
            interval: batteryStatusIndicatorImage.baseNameEquals ? 0 : chargeCableAnim.duration/2
            onTriggered: batteryStatusIndicatorImage.source = batteryStatusIndicatorImage.sourceValue
        }
    }

    Text {
        id: batteryStatusIndicatorText
        anchors {
            left: batteryStatusIndicatorImage.right
            leftMargin: Theme.paddingSmall
            verticalCenter: parent.verticalCenter
        }

        font {
            family: Theme.fontFamilyHeading
            pixelSize: Theme.fontSizeSmall
        }
        text: batteryStatus.chargePercentage < 0 ? "" : batteryStatus.chargePercentage + "%"
        color: batteryStatusIndicator.palette.primaryColor
    }
}
