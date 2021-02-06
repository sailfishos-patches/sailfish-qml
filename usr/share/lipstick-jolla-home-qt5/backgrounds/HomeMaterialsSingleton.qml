/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0

QtObject {
    id: materials

    property Material undimmed: Material {
        objectName: "undimmed"

        vertexShader: "
attribute highp vec4 position;

uniform highp mat4 positionMatrix;
uniform highp mat4 transformMatrix;

varying highp vec2 homeCoord;

void backgroundMain() {
    gl_Position = positionMatrix * position;
    homeCoord = (transformMatrix * gl_Position).xy;
}
"

        fragmentShader: "
uniform lowp sampler2D homeTexture;

varying highp vec2 homeCoord;

void backgroundMain() {
    gl_FragColor = texture2D(homeTexture, homeCoord);
}
"
    }

    property Material dimming: Material {
        objectName: "dimming"

        vertexShader: "
attribute highp vec4 position;

uniform highp mat4 positionMatrix;
uniform highp mat4 transformMatrix;
uniform highp mat4 sourceMatrix;

varying highp vec2 homeCoord;
varying highp vec2 sourceCoord;

void backgroundMain() {
    gl_Position = positionMatrix * position;
    homeCoord = (transformMatrix * gl_Position).xy;
    sourceCoord = (sourceMatrix * gl_Position).xy;
}
"

        fragmentShader: "
uniform lowp sampler2D sourceTexture;
uniform lowp sampler2D homeTexture;
uniform lowp vec4 color;
uniform lowp float percentageDimmed;

varying highp vec2 sourceCoord;
varying highp vec2 homeCoord;

void backgroundMain() {
    lowp vec4 dimmed = background2D(sourceTexture, sourceCoord);
    dimmed = (dimmed * (1.0 - color.a)) + color;

    gl_FragColor = texture2D(homeTexture, homeCoord);
    gl_FragColor = mix(gl_FragColor, dimmed, percentageDimmed);
}
"
    }

    property Material dimmed: Material {
        objectName: "dimmed"

        vertexShader: "
attribute highp vec4 position;

uniform highp mat4 positionMatrix;
uniform highp mat4 sourceMatrix;

varying highp vec2 sourceCoord;

void backgroundMain() {
    gl_Position = positionMatrix * position;
    sourceCoord = (sourceMatrix * gl_Position).xy;
}
"

        fragmentShader: "
uniform lowp sampler2D sourceTexture;
uniform lowp vec4 color;

varying highp vec2 sourceCoord;

void backgroundMain() {
    gl_FragColor = background2D(sourceTexture, sourceCoord);
    gl_FragColor = (gl_FragColor * (1.0 - color.a)) + color;
}
"
    }
}
