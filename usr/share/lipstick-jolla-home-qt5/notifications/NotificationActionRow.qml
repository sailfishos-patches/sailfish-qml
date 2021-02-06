/****************************************************************************
 **
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0

Grid {
    id: root

    property bool active: true
    property alias count: repeater.count
    property alias animating: heightAnimation.running
    property int visibleCount: {
        var count = 0
        if (notification) {
            var actions = notification.remoteActions
            for (var i = 0; i < actions.length; i++) {
                var name = actions[i].name
                if (name && name.length > 0 && name !== "default" && name !== "app") {
                    count = count + 1
                }
            }
        }
        return count
    }

    signal actionInvoked(string actionName)

    property bool _active: active && visibleCount > 0
    property int _totalWidth
    property int _currentMaxButtonWidth: Theme.buttonWidthExtraSmall

    on_ActiveChanged: if (_active) repeater.model = notification.remoteActions
    Component.onCompleted: if (_active) repeater.model = notification.remoteActions

    function calculateTotalWidth() {
        var maxButtonWidth = 0
        var width = 0
        for (var i = 0; i < count; i++) {
            var button = repeater.itemAt(i)
            if (button && button.text.length > 0) {
                width = width + button.implicitWidth + spacing
                maxButtonWidth = Math.max(maxButtonWidth, button.implicitWidth)
            }
        }
        _currentMaxButtonWidth = maxButtonWidth
        _totalWidth = width
    }

    spacing: Theme.paddingMedium
    horizontalItemAlignment: Grid.AlignRight
    columns: _totalWidth > parent.width ? 1 : visibleCount
    height: _active ? implicitHeight : 0
    Behavior on height {
        NumberAnimation {
            id: heightAnimation
            easing.type: Easing.InOutQuad
            duration: 200
        }
    }

    opacity: _active ? 1.0 : 0.0
    Behavior on opacity { FadeAnimator {}}
    enabled: _active

    Repeater {
        id: repeater

        delegate: SecondaryButton {
            preferredWidth: Theme.buttonWidthExtraSmall
            text: modelData.name !== "default" && modelData.name !== "app"
                  ? (modelData.displayName || "")
                  : ""
            visible: text.length > 0
            onImplicitWidthChanged: calculateTotalWidth()

            width: columns === 1 ? _currentMaxButtonWidth : implicitWidth

            onClicked: root.actionInvoked(modelData.name)
        }
    }

    Connections {
        target: notification
        onRemoteActionsChanged: if (_active) repeater.model = notification.remoteActions
    }
}
