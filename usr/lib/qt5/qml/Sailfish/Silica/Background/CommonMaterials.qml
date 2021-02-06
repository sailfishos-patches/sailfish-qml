/*
 * Copyright (c) 2015 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica.private 1.0

QtObject {
    id: materials

    property var materialNames: [ "glass", "blur" ]

    property list<QtObject> objects
    default property alias _objects: materials.objects

    readonly property string backgroundVertexShader: "
attribute highp vec4 position;

uniform highp mat4 positionMatrix;
uniform highp mat4 backgroundMatrix;

varying highp vec2 backgroundCoord;

void backgroundMain() {
    gl_Position = positionMatrix * position;
    backgroundCoord = (backgroundMatrix * gl_Position).xy;
}
"

    // MaterialPrivate is used in place of Material in types which are instantiated in the the Materials
    // singleton which can't import Sailfish.Silica.Background.
    property MaterialPrivate glass: GlassMaterial {}
    property MaterialPrivate blur: BlurMaterial {}

    property MaterialPrivate opaqueColor: MaterialPrivate {
        id: colorMaterial

        vertexShader: "
attribute highp vec4 position;

uniform highp mat4 positionMatrix;

void backgroundMain() {
    gl_Position = positionMatrix * position;
}
"

        fragmentShader: "
uniform lowp vec4 color;

void backgroundMain() {
    gl_FragColor = color;
}
"
        blending: false
    }
    property MaterialPrivate translucentColor: MaterialPrivate {
        vertexShader: colorMaterial.vertexShader
        fragmentShader: colorMaterial.fragmentShader
        blending: true
    }
}
