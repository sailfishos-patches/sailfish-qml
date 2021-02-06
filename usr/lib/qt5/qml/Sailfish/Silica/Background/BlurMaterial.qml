/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica.private 1.0

// MaterialPrivate is used in place of Material in types which are instantiated in the the Materials
// singleton which can't import Sailfish.Silica.Background.
MaterialPrivate {
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
