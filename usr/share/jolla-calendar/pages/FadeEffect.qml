import QtQuick 2.0

ShaderEffect {
    id: root

    property ShaderEffectSource source
    property int sourceOffset: 0
    property int sourceHeight: source.sourceItem.height

    // 0 - top and bottom, 1 - top, 2 - bottom
    property int fadeMode

    mesh: Qt.size(1, (fadeMode == 0)?3:2)

    property real fade: 0.05

    property real _sourceTextureHeight: source.sourceItem?source.sourceItem.height:1
    property real _sourceOffset: sourceOffset / _sourceTextureHeight
    property real _sourceScale: sourceHeight / _sourceTextureHeight

    vertexShader: 
        "uniform highp mat4 qt_Matrix;
         uniform lowp float fade;
         uniform lowp float height;
         uniform int fadeMode;
         uniform lowp float qt_Opacity;
         uniform highp float _sourceScale;
         uniform highp float _sourceOffset;
         attribute highp vec4 qt_Vertex;
         attribute highp vec2 qt_MultiTexCoord0;
         varying highp vec2 qt_TexCoord0;
         varying lowp float opacity;
         void main() {

             highp float y = qt_MultiTexCoord0.y;
             if (y > 0. && (y < 0.5 || (fadeMode == 1 && y < 1.))) {
                 y = fade;
                 opacity = qt_Opacity;
             } else if (y < 1. && (y > 0.5 || (fadeMode == 2 && y > 0.))) {
                 y = 1. - fade;
                 opacity = qt_Opacity;
             } else if (y == 0.) {
                 if (fadeMode == 2) opacity = qt_Opacity;
                 else opacity = 0.;
             } else {
                 if (fadeMode == 1) opacity = qt_Opacity;
                 else opacity = 0.;
             }

             qt_TexCoord0 = vec2(qt_MultiTexCoord0.x, _sourceOffset + y * _sourceScale);
             gl_Position = qt_Matrix * vec4(qt_Vertex.x, y * height, qt_Vertex.zw);
         }"

    fragmentShader:
        "varying highp vec2 qt_TexCoord0;
         varying lowp float opacity;
         uniform sampler2D source;
         void main() {
             gl_FragColor = texture2D(source, qt_TexCoord0) * opacity;
         }"

} 

