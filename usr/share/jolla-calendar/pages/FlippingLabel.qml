import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    property string text
    property real fontSize: Theme.fontSizeSmall
    property string color: Theme.secondaryHighlightColor
    property bool animate: true

    property real _target: 0
    property real _rotation: _target

    Behavior on _rotation { SmoothedAnimation { velocity: 4 } }

    width: label2.label2visible() ? label2.width : label1.width
    height: label2.label2visible() ? label2.height : label1.height

    Text {
        id: label1
        visible: !label2.visible
        color: root.color
        font.pixelSize: root.fontSize

        transform: Rotation {
            origin { x: label1.width / 2; y: label1.height / 2 }
            axis { x: 1; y: 0; z: 0 }
            angle: (root._rotation % 2) * 180
        }
    }

    Text {
        id: label2
        function label2visible() { return r.angle > -90 && r.angle < 90 }
        visible: label2visible()
        color: root.color
        font.pixelSize: root.fontSize

        transform: Rotation {
            id: r
            origin { x: label2.width / 2; y: label2.height / 2 }
            axis { x: 1; y: 0; z: 0 }
            angle: -180 * (1 - (root._rotation % 2))
        }
    }

    onTextChanged: {
        if (animate) {
            if (!label2.label2visible()) label2.text = text
            else label1.text = text
            if (_target - _rotation < 0.5) _target++
        } else {
            if (!label2.label2visible()) label1.text = text
            else label2.text = text
        }
    }

    Component.onCompleted: label1.text = root.text
}
