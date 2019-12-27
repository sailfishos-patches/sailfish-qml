import QtQuick 2.2

Transition {
    id: trans
    property Item grid
    // This logic only works if we're inserting/removing single items
    property bool rowChange: (((ViewTransition.index+1) % grid.columns == 0 && ViewTransition.targetIndexes.length == 0  // Item removed
                              || ViewTransition.index % grid.columns == 0 && ViewTransition.targetIndexes.length != 0))  // Item added
    property bool menuChange: ViewTransition.item && ViewTransition.item.x == ViewTransition.destination.x
    SequentialAnimation {
        NumberAnimation { property: "opacity"; duration: trans.rowChange && !trans.menuChange ? 75 : 0; to: trans.rowChange && !trans.menuChange ? 0 : 1 }
        PropertyAction { property: "y" }
        NumberAnimation { properties: "x"; duration: trans.rowChange ? 0 : 150 }
        NumberAnimation { property: "opacity"; duration: trans.rowChange && !trans.menuChange ? 75 : 0; to: 1 }
    }
}
