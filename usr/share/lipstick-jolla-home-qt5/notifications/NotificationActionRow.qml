/****************************************************************************
 **
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

Item {
    id: root

    property QtObject notification
    property bool active: true
    property alias count: repeater.count
    property alias animating: heightAnimation.running
    property int textAreaMaxHeight: Screen.height
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

    signal actionInvoked(string actionName, string actionText)

    property bool replyActivationPending
    property bool replyTextActive
    onReplyTextActiveChanged: {
        if (replyTextActive) {
            replyTextLoader.active = true
        }
    }

    property string currentTextActionName
    property var currentTextAction: {
        if (notification && currentTextActionName != "") {
            var actions = notification.remoteActions
            for (var i = 0; i < actions.length; i++) {
                var action = actions[i]
                if (action.name === currentTextActionName) {
                    return action
                }
            }
        }
        return null
    }

    onActiveChanged: {
        if (!active) {
            replyTextActive = false
        }
    }

    onNotificationChanged: {
        if (buttonGrid._active && notification) {
            repeater.model = notification.remoteActions
        }
    }

    Connections {
        target: notification
        onRemoteActionsChanged: {
            if (buttonGrid._active) {
                repeater.model = notification.remoteActions
            }
        }
    }

    height: replyTextActive ? replyTextLoader.height : buttonGrid.height
    Behavior on height {
        NumberAnimation {
            id: heightAnimation
            easing.type: Easing.InOutQuad
            duration: 200
        }
    }

    function reset() {
        currentTextActionName = ""
        replyTextActive = false
    }

    Grid {
        id: buttonGrid

        property bool _active: notification && active && visibleCount > 0 && !root.replyTextActive
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
        anchors.right: parent.right
        columns: _totalWidth > parent.width ? 1 : visibleCount
        height: _active ? implicitHeight : 0

        opacity: _active ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {}}
        enabled: _active
        Repeater {
            id: repeater

            delegate: SecondaryButton {
                // on phone sized displays, try to squeeze in multiple buttons to fit on one line
                preferredWidth: (root.visibleCount > 2 && Screen.sizeCategory < Screen.Large)
                                ? Theme.buttonWidthTiny : Theme.buttonWidthExtraSmall
                text: modelData.name !== "default" && modelData.name !== "app"
                      ? (modelData.displayName || "")
                      : ""
                visible: text.length > 0
                onImplicitWidthChanged: buttonGrid.calculateTotalWidth()

                width: buttonGrid.columns === 1 ? buttonGrid._currentMaxButtonWidth : implicitWidth

                onClicked: {
                    if (modelData.type === "input") {
                        root.currentTextActionName = modelData.name
                        if (Lipstick.compositor.lockScreenLayer.lockScreenEventsEnabled) {
                            root.replyActivationPending = true
                            Lipstick.compositor.unlock()
                        } else {
                            root.replyTextActive = true
                        }
                    } else {
                        root.actionInvoked(modelData.name, "")
                    }
                }
            }
        }
    }

    Connections {
        target: Lipstick.compositor.lockScreenLayer
        onDeviceIsLockedChanged: {
            if (root.replyActivationPending && !Lipstick.compositor.lockScreenLayer.deviceIsLocked) {
                root.replyTextActive = true
                root.replyActivationPending = false
            }
        }
        onShowingLockCodeEntryChanged: {
            if (!Lipstick.compositor.lockScreenLayer.showingLockCodeEntry) {
                root.replyActivationPending = false
            }
        }
    }

    Loader {
        id: replyTextLoader

        active: false
        sourceComponent: replyTextComponent
    }

    Component {
        id: replyTextComponent

        Item {
            opacity: root.replyTextActive ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation {} }
            visible: opacity > 0
            width: root.width
            height: Math.max(actionTextArea.height, actionTextEnter.height + 2*Theme.paddingSmall)

            TextArea {
                id: actionTextArea

                textLeftMargin: 0
                textRightMargin: Theme.paddingMedium
                height: Math.min(implicitHeight, Theme.itemSizeLarge*2, root.textAreaMaxHeight)
                anchors.left: parent.left
                anchors.right: actionTextEnter.left
                placeholderText: root.currentTextAction ? root.currentTextAction.displayName : ""
                labelVisible: false // the placeholder is enough
                // avoid implicit inverted color on the keyboard side just because a popup might have such
                _keyboardPalette: ""
                _appWindow: undefined // suppress warnings

                Component.onCompleted: forceActiveFocus()
            }

            Button {
                id: actionTextEnter

                height: implicitHeight + 2*Theme.paddingSmall
                enabled: actionTextArea.text != ""
                icon.source: "image://theme/icon-m-send"
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingSmall

                onClicked: {
                    root.actionInvoked(root.currentTextActionName, actionTextArea.text)
                    actionTextArea.text = ""
                }
            }

            Connections {
                target: root
                onCurrentTextActionNameChanged: actionTextArea.text = ""
                onReplyTextActiveChanged: {
                    if (root.replyTextActive) {
                        actionTextArea.forceActiveFocus()
                    }
                }
            }
        }
    }
}
