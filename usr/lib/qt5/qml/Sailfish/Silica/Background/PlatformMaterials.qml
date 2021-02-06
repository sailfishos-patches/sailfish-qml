/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica.private 1.0

CommonMaterials {
    id: materials

    materialNames: [ "glass", "blur", "monochrome" ]

    // MaterialPrivate is used in place of Material in types which are instantiated in the the Materials
    // singleton which can't import Sailfish.Silica.Background.
    property MaterialPrivate monochrome: MaterialPrivate {
        fragmentShader: "
uniform lowp sampler2D sourceTexture;
uniform lowp vec4 color;
uniform lowp vec4 highlightColor;

varying highp vec2 sourceCoord;
varying highp vec2 patternCoord;

void backgroundMain() {
    lowp vec4 source = background2D(sourceTexture, sourceCoord);
    lowp float grey = dot(source.rgb, vec3(0.222, 0.707, 0.071));

    gl_FragColor = mix(vec4(highlightColor.rgb * grey, source.a), source, 0.2);
    gl_FragColor = (gl_FragColor * (1.0 - color.a)) + color;
}
"
    }
}
