import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    property string title
    property bool animate: true

    property real _target: 0
    property real _rotation: _target

    Behavior on _rotation { SmoothedAnimation { velocity: 4 } }

    height: ph1.height

    PageHeader {
        id: ph1
        visible: !ph2.visible
        height: isPortrait ? Theme.itemSizeLarge : Theme.itemSizeMedium

        transform: Rotation {
            origin { x: ph1.width / 2; y: ph1.height / 2 }
            axis { x: 1; y: 0; z: 0 }
            angle: (root._rotation % 2) * 180
        }
    }

    PageHeader {
        id: ph2
        function ph2visible() { return r.angle > -90 && r.angle < 90 }
        visible: ph2visible()
        height: ph1.height

        transform: Rotation {
            id: r
            origin { x: ph1.width / 2; y: ph1.height / 2 }
            axis { x: 1; y: 0; z: 0 }
            angle: -180 * (1 - (root._rotation % 2))
        }
    }

    onTitleChanged: {
        if (animate) {
            if (!ph2.ph2visible()) ph2.title = title
            else ph1.title = title
            if (_target - _rotation < 0.5) _target++
        } else {
            if (!ph2.ph2visible()) ph1.title = title
            else ph2.title = title
        }
    }

    Component.onCompleted: ph1.title = root.title
}
