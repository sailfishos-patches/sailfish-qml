/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Martin Jones <martin.jones@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import com.jolla.lipstick 0.1
import org.freedesktop.contextkit 1.0

ShaderEffect {
    id: cellularSignalStrengthStatusIndicator
    property bool updatesEnabled: true
    property int modem
    property string modemContext: Desktop.cellularContext(modem)
    property string maskBase: cellularRegistrationStatusContextProperty.value === 'no-sim'
                              ? "image://theme/icon-status-no-sim"
                              : (cellularRegistrationStatusContextProperty.value === "roam"
                                 ? "image://theme/icon-status-roaming-sim" : "image://theme/icon-status-cellular-sim")
    property bool masked: Telephony.multiSimSupported // && cellularRegistrationStatusContextProperty.value !== "no-sim"

    ContextProperty {
        id: cellularSignalBarsContextProperty
        key: modemContext + ".SignalBars"
    }

    ContextProperty {
        id: cellularRegistrationStatusContextProperty
        key: modemContext + ".RegistrationStatus"
    }

    width: img.width
    height: img.height
    visible: img.source != ''

    property variant source: img
    property variant maskSource: mask

    fragmentShader: "
        varying highp vec2 qt_TexCoord0;
        uniform highp float qt_Opacity;
        uniform lowp sampler2D source;" + (masked
            ? "uniform lowp sampler2D maskSource;
               void main(void) { gl_FragColor = texture2D(source, qt_TexCoord0.st) * texture2D(maskSource, qt_TexCoord0.st).a * qt_Opacity; }"
            : "void main(void) { gl_FragColor = texture2D(source, qt_TexCoord0.st) * qt_Opacity; }")

    Image {
        id: img
        visible: false
        source: {
            var path = function(name) {
                return "image://theme/icon-status-" + name + iconSuffix
            }

            if (fakeOperator !== "")
                return path(masked ? "strength-5" : "cellular-5")

            if (cellularRegistrationStatusContextProperty.value == undefined)
                return ""

            switch (cellularRegistrationStatusContextProperty.value) {
            case "no-sim":
                return path("no-sim")
            case "offline":
                return path(masked ? "no-cellular-masked" : "no-cellular")
            case "home":
            case "roam":
                var bars = cellularSignalBarsContextProperty.value
                bars = (bars === undefined ? "0" : bars)
                return path((masked ? "strength-" : "cellular-") + bars)
            default:
                return path("invalid")
            }
        }
        onSourceChanged: {
            // ShaderEffect must be coaxed into changing its image
            cellularSignalStrengthStatusIndicator.source = undefined
            cellularSignalStrengthStatusIndicator.source = img
        }
    }

    Image {
        id: mask
        visible: false
        source: masked ? maskBase + modem + "-mask" : ""
        onSourceChanged: {
            // ShaderEffect must be coaxed into changing its image
            cellularSignalStrengthStatusIndicator.maskSource = undefined
            cellularSignalStrengthStatusIndicator.maskSource = masked ? mask : undefined
        }
    }

    onUpdatesEnabledChanged: {
        if (updatesEnabled) {
            cellularSignalBarsContextProperty.subscribe()
            cellularRegistrationStatusContextProperty.subscribe()
        } else {
            cellularSignalBarsContextProperty.unsubscribe()
            cellularRegistrationStatusContextProperty.unsubscribe()
        }
    }
}
