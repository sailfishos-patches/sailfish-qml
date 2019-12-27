import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    property int columnHeight

    // model below displays 7 lines, plus 2 spacings each half item height
    property int itemHeight: (columnHeight - y) / 8

    width: parent.width
    y: Theme.paddingMedium
    spacing: Math.round(itemHeight/2)

    Repeater {
        model: [ [ 0.8, 0.65 ], [ 0.7, 0.8, 0.55 ], [ 0.6, 0.7 ] ]

        delegate: Column {
            id: group

            property bool rightAlign: index % 2 == 1

            spacing: 1
            width: parent ? parent.width : 0

            Repeater {
                model: modelData

                delegate: Item {
                    x: Theme.paddingMedium
                    width: parent ? parent.width - 2*x : 0
                    height: itemHeight - 1

                    Rectangle {
                        width: parent.width * modelData
                        x: group.rightAlign ? parent.width - width : 0
                        height: parent.height
                        radius: Theme.paddingSmall/2
                        color: 'white'
                        opacity: Theme.opacityLow
                    }
                }
            }
        }
    }
}
