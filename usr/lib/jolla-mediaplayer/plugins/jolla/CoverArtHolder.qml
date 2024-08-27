// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    property Item view
    property Item coverArt

    Component.onCompleted: {
        coverArt.parent = coverHolder
        view.contentWidth = Qt.binding(function() { return view.width - width })
    }

    Component.onDestruction: view.contentWidth = Qt.binding(function() { return view.width })

    Rectangle {
        anchors {
            top: coverHolder.top
            bottom: parent.bottom
            left: coverHolder.left
            right: coverHolder.right
        }
        color: Theme.highlightBackgroundColor
        opacity: Theme.opacityHigh
    }

    Item {
        id: coverHolder

        opacity: coverArt.status === Image.Ready ? 1.0 : 0.0

        Behavior on opacity { FadeAnimation {} }

        x: root.view.contentWidth - width
        y: (root.view.contentItem.y - view.headerItem.height) > 0 ? root.view.contentItem.y - root.view.headerItem.height : 0
        width: parent.width
        height: width
    }
}
