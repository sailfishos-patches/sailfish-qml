/*
 * Copyright (c) 2015 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

ShaderEffect {
    id: vignette

    // radius the opened vignette, where 0.5 results in a circle fitting the screen
    property real openRadius: 0.85
    readonly property bool opened: active && Math.abs(radius - openRadius) < 0.01
    property bool active
    readonly property size size: Qt.size(width, height)
    property bool animated

    property real radius: active ? openRadius : 0.0
    Behavior on radius {
        enabled: vignette.animated
        NumberAnimation {
            duration: 300
        }
    }

    // softness of our vignette, between 0.0 and 1.0
    property real softness: 0.2
    property color color: radius < openRadius / 2 ? "black" : Theme.overlayBackgroundColor
    Behavior on color {
        enabled: vignette.animated
        ColorAnimation {
            duration: vignette.opened ? 800 : 300
        }
    }

    property real strength: radius < openRadius / 2 ? 1.0 : (Theme.colorScheme === Theme.DarkOnLight ? 0.3 : 0.6)
    Behavior on strength {
        enabled: vignette.animated
        FadeAnimation {
            duration: vignette.opened ? 800 : 300
            properties: "strength"
        }
    }

    mesh: GridMesh { resolution: Qt.size(32, 32) }
    vertexShader: "
        uniform highp mat4 qt_Matrix;
        attribute highp vec4 qt_Vertex;
        attribute highp vec2 qt_MultiTexCoord0;
        varying lowp float vignette;
        uniform float radius;
        uniform float softness;
        uniform float strength;
        uniform float qt_Opacity;
        uniform highp vec2 size;

        void main() {
            gl_Position = qt_Matrix * qt_Vertex;
            vec2 position = qt_Vertex.xy / size - vec2(0.5);

            float len = length(position);

            // our vignette effect, using smoothstep
            vignette = smoothstep(radius, radius - softness, len);
            vignette = (1.0 - mix(1.0, vignette, strength)) * qt_Opacity;
        }
    "

    fragmentShader: "
        varying lowp float vignette;
        uniform mediump vec4 color;

        void main()
        {
            gl_FragColor = color * vignette;
        }"
}
