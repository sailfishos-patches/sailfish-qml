/*
 * Copyright (c) 2015 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica.private 1.0

// MaterialPrivate is used in place of Material in types which are instantiated in the the Materials
// singleton which can't import Sailfish.Silica.Background.
MaterialPrivate {
        fragmentShader: "
uniform lowp sampler2D sourceTexture;
uniform lowp sampler2D patternTexture;
uniform lowp vec4 color;

varying highp vec2 sourceCoord;
varying highp vec2 patternCoord;

void backgroundMain() {
    lowp vec4 pattern = texture2D(patternTexture, patternCoord) * 0.1;

    gl_FragColor = background2D(sourceTexture, sourceCoord);
    gl_FragColor = (gl_FragColor * (1.0 - color.a)) + color;
    gl_FragColor = (gl_FragColor * (1.0 - pattern.a)) + pattern;
}
"
}
