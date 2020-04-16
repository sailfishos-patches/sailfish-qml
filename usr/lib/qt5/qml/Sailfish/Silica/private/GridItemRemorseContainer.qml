import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: root

    readonly property Item remorse: gridItem.__silica_remorse_item

    z: 1
    clip: true
    x: -gridItem.x
    y: contentItem.height
    width: _flickable ? _flickable.width : Screen.width
    parent: gridItem

    states: [
        State {
            name: "remorse"
            when: !!remorse && (!_gridView || !_gridView.__silica_contextmenu_instance) && !(gridItem._menuItem && gridItem._menuItem.parent)
            PropertyChanges {
                target: gridItem
                z: 1000
                implicitHeight: contentItem.height + root.height
            }
            PropertyChanges {
                target: root
                height: remorse.state === "active" ? Theme.itemSizeMedium : 0
            }
            PropertyChanges {
                target: gridItem.contentItem
                opacity: remorse.state === "" ? 1.0 : 0.0
            }
        }
    ]

    Connections {
        target: remorse
        onStateChanged: if (remorse && remorse.state === "active") _calculateMenuOffset()
    }

    Behavior on height {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Item {
        id: remorseContent
        anchors.fill: parent

        Component.onCompleted: __silica_remorse_content = remorseContent

    }
    Binding {
        target: _gridView
        property: "__silica_remorse_height"
        when: !!(gridItem.__silica_remorse_item && _gridView && !_gridView.__silica_contextmenu_instance)
        value: root.height
    }
    Connections {
        target: _gridView
        onWidthChanged: _calculateMenuOffset()
    }
}
