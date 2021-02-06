/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

pragma Singleton
import QtQuick 2.6
import Sailfish.Silica.Background 1.0
import Sailfish.Silica 1.0

SequenceFilter {
    ConvolutionFilter {
        kernel: Kernel.gaussian(Kernel.SampleSize5)
    }

    ShaderFilter {
        fragmentShader: "
uniform lowp sampler2D sourceTexture;
uniform lowp vec4 color;
varying highp vec2 sourceCoord;

void main() {
    gl_FragColor = color * ceil(texture2D(sourceTexture, sourceCoord).a);
}
"
    }

    RepeatFilter {
        repetitions: 1

        ConvolutionFilter {
            kernel: Kernel.gaussian(Kernel.SampleSize9, 5)
        }
    }
}
