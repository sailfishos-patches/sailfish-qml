/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Martin Jones <martin.jones@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1
import com.jolla.settings 1.0
import org.nemomobile.lipstick 0.1
import org.nemomobile.devicelock 1.0
import "../main"

EditableGridDelegate {
    id: wrapper

    property string settingsEntryPath: model.object.location().join('/')
    property alias actionSource: loader.actionSource
    property alias pageSource: loader.pageSource
    property alias item: loader.item
    property alias removeButtonVisible: removeButton.visible
    property real reorderScale: 1.3

    readonly property var contextMenu: item ? item._menuItem : null
    readonly property real contextMenuHeight: contextMenu ? contextMenu.height : 0
    readonly property bool contextMenuOpen: !!contextMenu && contextMenu._open

    signal remove()

    visible: true
    editMode: Lipstick.compositor.topMenuLayer.housekeeping
    animateMovement: Desktop.instance && !Desktop.instance.orientationTransitionRunning
            && !manager.itemResizing

    // While any delegate is opening/closing its menu, disable the automatic delegate
    // height change animations in the grid.
    onContextMenuOpenChanged: {
        manager.itemResizing = contextMenuOpen
    }

    SettingComponentLoader {
        id: loader

        readonly property var parameters: settingsObject && settingsObject.data()["params"] || {}
        readonly property bool gridObject: parameters.type === "grid"

        anchors.centerIn: parent
        scale: wrapper.reordering ? reorderScale : 1.0
        transformOrigin: Item.Bottom
        Behavior on scale { NumberAnimation { easing.type: Easing.InOutQuad } }
        opacity: enabled ? 1.0 : Theme.opacityOverlay
        enabled: !wrapper.editMode

        settingsObject: model.object

        Binding {
            when: loader.item.userAccessRestricted !== undefined
            target: loader.item
            property: "userAccessRestricted"
            value: Desktop.deviceLockState !== DeviceLock.Unlocked && loader.item.privileged === true
        }

        // Ensure the flickable contentY doesn't scroll upwards if the opening of the menu expands
        // the flickable contentHeight beyond the current top window dimensions.
        Binding {
            target: loader.item && loader.item._menuItem ? loader.item._menuItem : null
            property: "container"
            value: Lipstick.compositor.topMenuLayer.topMenu.parent
        }

        Connections {
            target: loader.item
            ignoreUnknownSignals: true
            onRequestUserAccess: {
                Lipstick.compositor.topMenuLayer.topMenu.requestUserAccessForControl(loader.item)
            }
        }
    }

    Image {
        id: removeButton
        property bool pressed
        function containsPoint(x, y) {
            var pos = contentItem.mapToItem(removeButton, x, y)
            pos.x -= removeButton.width/2
            pos.y -= removeButton.height/2
            var diff = pos.x*pos.x + pos.y*pos.y
            return Math.sqrt(diff) < removeButton.width/2
        }

        source: "image://theme/icon-m-clear?" + (pressed ? Theme.highlightColor : Theme.primaryColor)
        z: 1
        anchors {
            right: loader.right
            bottom: loader.bottom
            margins: Theme.paddingMedium
        }
        enabled: Lipstick.compositor.topMenuLayer.housekeeping
        opacity: enabled ? 1.0 : 0
        Behavior on opacity { FadeAnimation { } }
    }

    // The remove button covers quite a lot of the icon, which can make reordering difficult
    // so, rather than use a separate MouseArea, handle clicking on the remove icon
    // in our existing MouseArea.
    onPressed: if (editMode) removeButton.pressed = removeButton.containsPoint(_pressX, _pressY)
    onDraggedChanged: if (dragged) removeButton.pressed = false
    onReleased: {
        if (removeButton.pressed) {
            removeButton.pressed = false
            if (removeButton.containsPoint(contentItem.mouseX, contentItem.mouseY)) {
                wrapper.remove()
            }
        }
    }
    onCanceled: removeButton.pressed = false
    onEditModeChanged: if (!editMode) removeButton.pressed = false

    Connections {
        target: item
        onClicked: wrapper.clicked()
    }

    Connections {
        target: Lipstick.compositor.topMenuLayer
        onActiveChanged: {
            if (!Lipstick.compositor.topMenuLayer.active && contextMenu) {
                contextMenu.close()
            }
        }
    }
}
