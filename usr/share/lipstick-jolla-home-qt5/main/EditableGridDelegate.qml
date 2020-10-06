/*
 * Copyright (c) 2015 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.1
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Lipstick 1.0

/*
    EditableGridDelegate / EditableGridManager provide draggable delegates to
    either a GridView or a Grid.

*/

Item {
    id: wrapper
    property var manager
    property int modelIndex: index
    property bool reordering
    property bool down: !reordering && !editMode && delegateContentItem.pressed && delegateContentItem.containsMouse
    property bool isFolder
    property int folderItemCount
    property bool editMode
    property bool dragged
    property bool animateMovement: true

    property real offsetY: y

    property alias contentItem: delegateContentItem
    default property alias _content: delegateContentItem.data
    property alias scale: delegateContentItem.scale

    property real _oldY
    property real _pressX
    property real _pressY
    property var _previousMovePosition
    property real _viewWidth
    property int _newIndex: -1
    property int _newFolderIndex: -1
    property real _currentViewWidth: manager.view.width
    on_CurrentViewWidthChanged: {
        cancelAnimation()
        moveTimer.running = true
    }

    signal beginReordering()
    signal reorder(int newIndex, int newFolderIndex)
    signal endReordering()

    signal clicked()
    signal pressed()
    signal released()
    signal pressAndHold()
    signal canceled()

    onAnimateMovementChanged: if (!animateMovement) cancelAnimation()

    function cancelAnimation() {
        slideMoveAnim.stop()
        fadeMoveAnim.stop()
        moveTimer.stop()
    }

    function startReordering(now) {
        manager.movingItem = delegateContentItem
        _previousMovePosition = undefined
        _newIndex = -1
        _newFolderIndex = -1
        if (now) {
            manager.startReorderTimer.stop()
            manager.startReorderTimer.triggered()
        } else {
            manager.startReorderTimer.restart()
        }
    }

    visible: false // I'm a placeholder. launcherItem does all the painting

    onEditModeChanged: {
        if (!editMode) {
            delegateContentItem.cancelReordering()

        }
    }

    Timer {
        id: moveTimer
        interval: 1
        onTriggered: {
            if (_viewWidth !== manager.view.width) {
                // Don't animate when created or view is resized
                delegateContentItem.x = wrapper.x
                delegateContentItem.y = wrapper.offsetY
                _viewWidth = manager.view.width
                _oldY = y
            } else if (!reordering) {
                if (y != _oldY && wrapper.width != manager.view.width) {
                    slideMoveAnim.stop()
                    fadeMoveAnim.start()
                } else if (!fadeMoveAnim.running) {
                    slideMoveAnim.restart()
                }
                _oldY = y
            }
        }
    }

    MouseArea {
        id: delegateContentItem

        function startReordering() {
            if (editMode && !dragged) {
                reparent(manager.dragContainer)
                manager.reorderItem = delegateContentItem
                drag.target = delegateContentItem
                z = 1000
                reordering = true
                dragged = true
                wrapper.beginReordering()
            }
        }

        function doReordering() {
            wrapper.reorder(_newIndex, _newFolderIndex)
            _newIndex = -1
        }

        function cancelReordering() {
            if (manager.startReorderTimer.running) {
                manager.startReorderTimer.stop()
            }
            if (reordering) {
                reordering = false
                manager.reorderTimer.stop()
                manager.stopScrolling()
                drag.target = null
                manager.reorderItem = null
                manager.folderItem = null
                manager.folderIndex = -1
                reparent(manager.contentContainer)
                slideMoveAnim.start()
            }
            if (manager.movingItem == delegateContentItem) {
                manager.movingItem = null
            }
        }

        function reparent(newParent) {
            var newPos = mapToItem(newParent, 0, 0)
            parent = newParent
            x = newPos.x - width/2 * (1-scale)
            y = newPos.y - height/2 * (1-scale)
        }

        function moved() {
            var gridViewPos = manager.contentContainer.mapFromItem(delegateContentItem, width/2, height/2)
            var item = manager.itemAt(gridViewPos.x, gridViewPos.y)
            if (!item && manager.view.spacing !== undefined) {
                // Grid has spacing between items
                item = manager.itemAt(gridViewPos.x - manager.view.spacing/2, gridViewPos.y)
                if (!item) {
                    item = manager.itemAt(gridViewPos.x + manager.view.spacing/2, gridViewPos.y)
                }
            }

            if (item && item !== wrapper && item.y !== wrapper.y) {
                var yDist = item.y - offsetY
                if (Math.abs(yDist) <= item.height - height/2) {
                    // Our items have differing heights and we don't have enough overlap yet
                    return
                }
            }

            var idx = -1
            var folderIdx = -1
            if (item && item !== wrapper) {
                if (!manager.supportsFolders) {
                    if (item.modelIndex !== index) {
                        idx = item.modelIndex
                    }
                } else {
                    var offset = gridViewPos.x - item.x
                    var folderThreshold = manager.supportsFolders && !isFolder ?
                                item.width / 4 : item.width / 2
                    if (offset < folderThreshold) {
                        if (Math.abs(index - item.modelIndex) > 1 || index > item.modelIndex || item.y !== wrapper.offsetY) {
                            idx = index < item.modelIndex ? item.modelIndex - 1 : item.modelIndex
                            manager.folderItem = null
                        }
                    } else if (offset >= item.width - folderThreshold) {
                        if (Math.abs(index - item.modelIndex) > 1 || index < item.modelIndex || item.y !== wrapper.offsetY) {
                            idx = index > item.modelIndex ? item.modelIndex + 1 : item.modelIndex
                            manager.folderItem = null
                        }
                    } else if (item.modelIndex !== index && manager.supportsFolders && item.folderItemCount < 99 && !isFolder) {
                        manager.folderItem = item
                        folderIdx = item.modelIndex
                    }
                }
            } else if (!item && gridViewPos.x >= 0 && gridViewPos.x < manager.view.width && gridViewPos.y >= 0) {
                idx = manager.itemCount() - 1
            }

            if (_newIndex !== idx) {
                _newIndex = idx;
                manager.reorderTimer.restart()
            }
            if (_newFolderIndex != folderIdx) {
                _newFolderIndex = folderIdx
                manager.reorderTimer.restart()
            }
            if (_previousMovePosition && manager.reorderTimer.running) {
                var xdiff = _previousMovePosition.x - gridViewPos.x
                var ydiff = _previousMovePosition.y - gridViewPos.y
                // Have we moved more than paddingSmall/2
                if (xdiff * xdiff + ydiff * ydiff > Theme.paddingSmall * Theme.paddingSmall / 4) {
                    manager.reorderTimer.restart()
                }
            }

            if (_newFolderIndex != manager.folderIndex) {
                manager.folderIndex = -1
            }

            var maxContentY = manager.pager.contentHeight - manager.pager.height
            var globalY = manager.pager.mapFromItem(delegateContentItem, 0, 0).y
            if (globalY <= 0 && manager.pager.contentY > 0) {
                manager.scroll(true)
            } else if (globalY + height >= manager.pager.height && manager.pager.contentY < maxContentY) {
                manager.scroll(false)
            } else {
                manager.stopScrolling()
            }

            _previousMovePosition = gridViewPos
        }

        objectName: "EditableGridDelegate_contentItem"
        x: wrapper.x
        y: wrapper.offsetY
        width: wrapper.width
        height: wrapper.height
        parent: manager.contentContainer
        transformOrigin: Item.Center

        onXChanged: if (wrapper.reordering) moved()
        onYChanged: if (wrapper.reordering) moved()
        onClicked: {
            if (!dragged) {
                wrapper.clicked()
            }
            dragged = false
        }
        onPressAndHold: wrapper.pressAndHold()

        onPressed: {
            if (manager.view.currentIndex !== undefined) {
                // The currentIndex will not be destroyed when we scroll out of view
                manager.view.currentIndex = index
            }
            if (editMode) {
                wrapper.startReordering()
            }
            _pressX = mouseX
            _pressY = mouseY
            dragged = false
            wrapper.pressed()
        }

        onPositionChanged: {
            if (!dragged && (Math.abs(_pressX-mouseX) > Theme.paddingLarge || Math.abs(_pressY-mouseY) > Theme.paddingLarge)) {
                dragged = true
            }
        }

        onReleased: {
            if (reordering) {
                wrapper.endReordering()
            }
            cancelReordering()
            wrapper.released()
        }

        onCanceled: {
            wrapper.canceled()
            cancelReordering()
            dragged = false
        }

        states: State {
            when: wrapper.animateMovement
            PropertyChanges {
                target: delegateContentItem
                explicit: true
                x: wrapper.x
                y: wrapper.y
            }
            PropertyChanges {
                target: wrapper
                onXChanged: {
                    moveTimer.running = true
                    manager.reorderTimer.stop()
                }
                onOffsetYChanged: {
                    moveTimer.running = true
                }
            }
        }

        Behavior on scale {
            NumberAnimation { easing.type: Easing.InOutQuad; duration: 150 }
        }

        ParallelAnimation {
            id: slideMoveAnim
            NumberAnimation { target: delegateContentItem; property: "x"; to: wrapper.x; duration: 150; easing.type: Easing.InOutQuad }
            NumberAnimation { target: delegateContentItem; property: "y"; to: wrapper.offsetY; duration: 150; easing.type: Easing.InOutQuad }
            onStopped: {
                // This is a safeguard. If the animation is canceled make sure the icon is left in
                // the correct state.
                delegateContentItem.x = wrapper.x
                delegateContentItem.y = wrapper.offsetY
            }
        }

        SequentialAnimation {
            id: fadeMoveAnim
            NumberAnimation { target: delegateContentItem; property: "opacity"; to: 0; duration: 75 }
            ScriptAction { script: { delegateContentItem.x = wrapper.x; delegateContentItem.y = wrapper.offsetY } }
            NumberAnimation { target: delegateContentItem; property: "opacity"; to: 1.0; duration: 75 }
            onStopped: {
                // This is a safeguard. If the animation is canceled make sure the icon is left in
                // the correct state.
                delegateContentItem.x = wrapper.x
                delegateContentItem.y = wrapper.offsetY
                delegateContentItem.opacity = 1.0
            }
        }
    }
}
