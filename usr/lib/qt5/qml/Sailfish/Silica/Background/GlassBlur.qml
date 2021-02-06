/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica.private 1.0

SequenceFilterPrivate {
    id: blur

    property int sampleSize: KernelPrivate.SampleSize17
    property real deviation: 5
    property alias kernel: convolutionFilter.kernel
    property alias repetitions: repeatFilter.repetitions
    property alias size: resizeFilter.size
    property alias saturationMultiplier: saturationFilter.saturationMultiplier
    property alias saturationOffset: saturationFilter.saturationOffset
    property alias valueMultiplier: saturationFilter.valueMultiplier
    property alias valueOffset: saturationFilter.valueOffset

    ResizeFilterPrivate {
        id: resizeFilter

        size { width: 256; height: 256 }
        fillMode: FillPrivate.PreserveAspectFit
    }

    ShaderFilterPrivate {
        id: saturationFilter

        property real saturationMultiplier: 1
        property real saturationOffset: 0
        property real valueMultiplier: 1
        property real valueOffset: 0

        enabled: saturationMultiplier != 1
                || saturationOffset != 0
                || valueMultiplier != 1
                || valueOffset != 0

        fragmentShader: "
uniform lowp sampler2D sourceTexture;
uniform lowp float saturationMultiplier;
uniform lowp float saturationOffset;
uniform lowp float valueMultiplier;
uniform lowp float valueOffset;
varying highp vec2 sourceCoord;

// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
lowp vec3 rgb2hsv(lowp vec3 c) {
    lowp vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    lowp vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
    lowp vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);

    lowp float d = q.x - min(q.w, q.y);
    lowp float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

lowp vec3 hsv2rgb(lowp vec3 c) {
    lowp vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    lowp vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    lowp vec4 source = texture2D(sourceTexture, sourceCoord);
    lowp vec3 hsv = rgb2hsv(source.rgb);

    hsv.y = clamp(0.0, 1.0, saturationOffset + (hsv.y * saturationMultiplier));
    hsv.z = clamp(0.0, 1.0, valueOffset + (hsv.z * valueMultiplier));

    gl_FragColor = vec4(hsv2rgb(hsv), source.a);
}
"
    }

    RepeatFilterPrivate {
        id: repeatFilter

        repetitions: 2

        ConvolutionFilterPrivate {
            id: convolutionFilter

            kernel: KernelPrivate.gaussian(blur.sampleSize, blur.deviation)
        }
    }
}
