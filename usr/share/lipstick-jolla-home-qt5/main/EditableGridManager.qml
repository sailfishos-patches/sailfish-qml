/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Martin Jones <martin.jones@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.1

QtObject {
    property Item view
    property Item pager
    property Item contentContainer
    property Item dragContainer: view.parent

    property Item reorderItem
    property Item movingItem
    property Item folderItem
    property int folderIndex: -1
    property bool supportsFolders
    property bool itemResizing

    signal scroll(bool up)
    signal stopScrolling()

    function itemAt(x, y) {
        // works for GridView. Overload for Grid/Repeater
        return view.itemAt(x, y)
    }

    function itemCount() {
        // works for GridView. Overload for Grid/Repeater
        return view.count
    }

    function setEditMode(enabled) {
        if (movingItem && !enabled) {
            movingItem.cancelReordering()
        }
    }

    property var startReorderTimer: Timer {
        interval: 150
        onTriggered: movingItem.startReordering()
    }

    property var reorderTimer: Timer {
        interval: folderItem && folderItem.isFolder ? 10 : 150
        onTriggered: movingItem.doReordering()
    }
}
