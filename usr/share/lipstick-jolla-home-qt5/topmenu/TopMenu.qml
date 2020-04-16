/****************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.5
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Nemo.Notifications 1.0 as SystemNotifications
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1
import org.nemomobile.configuration 1.0
import org.nemomobile.devicelock 1.0
import "../compositor"

SilicaFlickable {
    id: topMenu

    function scroll(up) {
        scrollAnimation.to = up ? 0 : contentHeight - height
        scrollAnimation.duration = Math.abs(contentY - scrollAnimation.to) * 1.5
        scrollAnimation.start()
    }

    function stopScrolling() {
        scrollAnimation.stop()
    }

    function requestUserAccessForControl(controlObject) {
        if (!!controlObject && Desktop.deviceLockState === DeviceLock.Locked) {
            _resetPendingControl(controlObject)
            Lipstick.compositor.unlock()
            Lipstick.compositor.topMenuLayer.hide()
        }
    }

    function _resetPendingControl(controlObject) {
        settingChangeNotifTimeout.stop()
        _pendingControl = controlObject
        _shouldTriggerPendingControl = false

        if (_pendingControl) {
            if (_pendingControl.hasOwnProperty("__jolla_settings_toggle")) {
                Lipstick.compositor.lockScreenLayer.unlockReason = _pendingControl.checked
                     //: Indicates device must be unlocked to disable a setting
                     //% "Unlock to disable setting"
                   ? qsTrId("lipstick_jolla_home-la-unlock_to_disable")
                     //: Indicates device must be unlocked to enable a setting
                     //% "Unlock to enable setting"
                   : qsTrId("lipstick_jolla_home-la-unlock_to_enable")
            } else {
                //: Indicates device must be unlocked to access a shortcut feature.
                //% "Unlock to access shortcut"
                Lipstick.compositor.lockScreenLayer.unlockReason = qsTrId("lipstick_jolla_home-la-unlock_to_access")
            }
            _shouldTriggerPendingControl = true
        } else {
            if (Lipstick.compositor && Lipstick.compositor.lockScreenLayer) {
                Lipstick.compositor.lockScreenLayer.unlockReason = ""
            }
            _shouldTriggerPendingControl = false
        }
    }

    NumberAnimation {
        id: scrollAnimation
        target: topMenu
        property: "contentY"
        easing.type: Easing.InOutQuad
        duration: 300
    }

    signal shutdown()
    signal reboot()

    readonly property int toggleColumns: Math.floor(width / Theme.itemSizeExtraLarge)
    property int itemSize: Math.round(width/toggleColumns)
    readonly property bool exposed: Lipstick.compositor.topMenuLayer.exposed
    readonly property real offset: Lipstick.compositor.topMenuLayer.absoluteExposure + contentY
    property alias exposedArea: background
    property var contextMenu

    property QtObject _pendingControl
    property bool _shouldTriggerPendingControl

    // When menu is fully open, keep it fixed at full content height instead of clipping the
    // sections to the available screen width.
    readonly property bool expanded: Lipstick.compositor.topMenuLayer.state == "visible"
                                     || Lipstick.compositor.topMenuLayer.state == "peeking"
                                     || (!atYEnd && Lipstick.compositor.topMenuLayer.state != "showing")

    onExposedChanged: {
        if (!exposed) {
            contentY = 0
            Lipstick.compositor.topMenuLayer.housekeeping = false
            ambienceSelector.resetView()
            if (contextMenu) {
                contextMenu.destroy()
            }
        }
    }

    width: Screen.sizeCategory >= Screen.Large ? Screen.height/2 : Screen.width
    contentHeight: column.height
    implicitHeight: Math.min(parent.height, contentHeight)
    interactive: !powerTransition.running && !scrollAnimation.running

    VerticalScrollDecorator {}

    BlurredBackground {
        id: background
        width: topMenu.width
        height: topMenu.expanded
                ? topMenu.contentHeight
                : Math.min(topMenu.height, Lipstick.compositor.topMenuLayer.absoluteExposure) + topMenu.y

        parent: _rotatingItem
        anchors.horizontalCenter: parent.horizontalCenter
        Binding { target: _rotatingItem; property: "opacity"; value: 1.0 } // hack, expose property in ApplicationWindow

        z: -1
    }

    Column {
        id: column
        width: parent.width
        Item {
            id: headerItem

            width: topMenu.width
            height: topMenu.itemSize

            states: [
                State {
                    name: "no-power"
                    when: Lipstick.compositor.topMenuLayer.active && !shutdownButton.visible
                }, State {
                    name: "power"
                    when: shutdownButton.visible
                    PropertyChanges {
                        target: lockButton
                        offset: -lockButton.height
                    }
                }
            ]
            transitions: Transition {
                id: powerTransition
                from: "no-power"
                to: "power"
                NumberAnimation {
                    target: lockButton
                    property: "offset"
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: topMenu
                    property: "contentY"
                    to: 0
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
            }

            Row {
                id: shutdownOptions

                y: Math.min(0, -height + topMenu.offset)

                width: topMenu.width
                height: topMenu.itemSize
                visible: Lipstick.compositor.powerKeyPressed
                PowerButton {
                    id: shutdownButton

                    width: parent.width / (rebootButton.visible ? 2 : 1)
                    height: parent.height

                    offset: lockButton.offset + height
                    onClicked: topMenu.shutdown()

                    iconSource: "image://theme/graphic-power-off"
                }

                PowerButton {
                    id: rebootButton

                    visible: rebootActionConfig.value
                    width: parent.width/2
                    height: parent.height

                    offset: lockButton.offset + height
                    onClicked: topMenu.reboot()

                    iconSource: "image://theme/graphic-reboot"

                    ConfigurationValue {
                        id: rebootActionConfig

                        key: "/desktop/jolla/reboot_action_enabled"
                        defaultValue: false
                    }
                }
            }

            PowerButton {
                id: lockButton

                y: Math.min(0, -height + topMenu.offset)

                width: topMenu.width
                height: topMenu.itemSize

                visible: !shutdownButton.visible || powerTransition.running

                onClicked: Lipstick.compositor.setDisplayOff()

                iconSource: "image://theme/graphic-display-blank"

                opacity: shutdownButton.opacity
            }
        }

        AmbienceSelector {
            id: ambienceSelector

            width: parent.width
            itemSize: topMenu.itemSize
            viewHeight: itemSize

            verticalOffset: topMenu.offset
            expanded: topMenu.expanded
        }

        SimSelector {
            verticalOffset: topMenu.offset
            // Circle behind toggle has diameter of Theme.itemSizeSmall. So between
            // two toggles are this much of space.
            // Don't divide by zero.
            innerMargin: toggleColumns > 0 ? (width / toggleColumns) - Theme.itemSizeSmall : 0
        }

        Loader {
            id: shortcutsLoader
            width: parent.width
            active: shortcutsEnabled.value || actionsEnabled.value ||  Desktop.showMultiSimSelector

            ConfigurationValue {
                id: shortcutsEnabled
                key: "/desktop/lipstick-jolla-home/topmenu_shortcuts_enabled"
                defaultValue: true
            }

            ConfigurationValue {
                id: actionsEnabled
                key: "/desktop/lipstick-jolla-home/topmenu_actions_enabled"
                defaultValue: true
            }
            sourceComponent: MouseArea {
                width: parent.width
                height: shortcutsColumn.height
                onClicked: Lipstick.compositor.topMenuLayer.housekeeping = false

                Column {
                    id: shortcutsColumn
                    width: parent.width

                    Item {
                        width: parent.width
                        height: favoriteSettingsLoader.height
                        clip: favoriteSettingsLoader.y < 0

                        FavoriteSettingsLoader {
                            id: favoriteSettingsLoader

                            y: Math.min(0, -height - shortcutsLoader.y + topMenu.offset)
                            width: parent.width
                            active: shortcutsEnabled.value
                            showListFavorites: true
                            columns: toggleColumns
                            pager: topMenu
                            padding: Theme.paddingLarge

                            states: State {
                                name: "expanded"
                                when: topMenu.expanded
                                PropertyChanges { target: favoriteSettingsLoader; y: 0 }
                            }

                            transitions: Transition {
                                to: "expanded"
                                NumberAnimation { properties: "y"; duration: 200 }
                            }
                        }
                    }

                    Item {
                        id: settingsContainer

                        clip: settingsButton.y < 0
                        width: parent.width
                        height: settingsButton.height + (!!contextMenu ? contextMenu.height : 0)

                        IconButton {
                            id: settingsButton

                            function openMenu() {
                                if (!topMenu.contextMenu) {
                                    topMenu.contextMenu = contextMenuComponent.createObject(topMenu)
                                }
                                topMenu.contextMenu.open(settingsContainer)
                            }

                            icon.source: "image://theme/icon-s-setting"

                            y: Math.min(0, -height - shortcutsLoader.y - favoriteSettingsLoader.height
                                        + topMenu.offset)

                            width: height + Theme.paddingMedium
                            height: Theme.itemSizeMedium
                            anchors.right: parent.right

                            Rectangle {
                                z: -1
                                anchors.fill: parent
                                color:  Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
                                visible: settingsButton.highlighted
                            }

                            onClicked: {
                                if (Lipstick.compositor.topMenuLayer.housekeeping) {
                                    Lipstick.compositor.topMenuLayer.housekeeping = false
                                } else {
                                    openMenu()
                                }
                            }

                            onPressAndHold: openMenu()

                            Component {
                                id: contextMenuComponent

                                ContextMenu {
                                    id: menu

                                    // Open the menu beneath the flickable, not within it.
                                    container: topMenu.parent

                                    onClosed: menu.destroy()

                                    MenuItem {
                                        //% "Organize"
                                        text: qsTrId("lipstick_jolla_home-me-topmenu_organize")
                                        color: Desktop.deviceLockState === DeviceLock.Unlocked ? _enabledColor : _disabledColor
                                        onClicked: {
                                            if (Desktop.deviceLockState === DeviceLock.Unlocked) {
                                                Lipstick.compositor.topMenuLayer.housekeeping = !Lipstick.compositor.topMenuLayer.housekeeping
                                            } else {
                                                housekeepingNotif.publish()
                                            }
                                        }
                                    }

                                    MenuItem {
                                        //% "Go to Top Menu settings"
                                        text: qsTrId("lipstick_jolla_home-me-topmenu_settings")
                                        onClicked: favoriteSettingsLoader.showTopMenuSettings()
                                    }
                                }
                            }
                        }

                        states: State {
                            name: "expanded"
                            when: topMenu.expanded
                            PropertyChanges { target: settingsButton; y: 0 }
                        }

                        transitions: Transition {
                            to: "expanded"
                            NumberAnimation { properties: "y"; duration: 200 }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: Desktop
        onDeviceLockStateChanged: {
            if (!!_pendingControl
                    && _shouldTriggerPendingControl
                    && Desktop.deviceLockState === DeviceLock.Unlocked) {
                // User has clicked a shortcut, then unlocked the device, so the shortcut can now
                // be triggered.
                if (_pendingControl.hasOwnProperty("__jolla_settings_toggle")) {
                    settingChangeNotif.reset(_pendingControl)
                    settingChangeNotifTimeout.restart()
                    _pendingControl.toggled()
                } else if (_pendingControl.hasOwnProperty("__lipstick_favorite_settings_item")) {
                    _pendingControl.triggered()
                }
                _shouldTriggerPendingControl = false
            }
        }
    }

    Connections {
        target: Lipstick.compositor.lockScreenLayer
        onShowingLockCodeEntryChanged: {
            if (!Lipstick.compositor.lockScreenLayer.showingLockCodeEntry
                    && Desktop.deviceLockState !== DeviceLock.Unlocked) {
                // User moved away from lock code entry screen without unlocking the device,
                // so cancel the pending triggering of the shortcut.
                topMenu._resetPendingControl(null)
            }
        }
    }

    Connections {
        target: _pendingControl
        ignoreUnknownSignals: true

        onCheckedChanged: {
            if (settingChangeNotifTimeout.running) {
                // A toggle-type shortcut has changed its state, presumably due to the delayed
                // triggering of the shorcut after unlocking, so notify the user of this change.
                settingChangeNotif.publish()
            }
            topMenu._resetPendingControl(null)
        }

        Component.onDestruction: {
            topMenu._resetPendingControl(null)
        }
    }

    // If toggled() has been called on a toggle-type shortcut but its 'checked' value hasn't
    // changed after some time (i.e. some error occurred), cancel the pending notification.
    Timer {
        id: settingChangeNotifTimeout
        interval: 5000
        onTriggered: {
            topMenu._resetPendingControl(null)
        }
    }

    SystemNotifications.Notification {
        id: housekeepingNotif

        //% "Unlock device to organize Top Menu"
        previewBody: qsTrId("lipstick_jolla_home-la-unlock_to_organize_top_menu")
        icon: "icon-system-resources"

        // Show notification above the device lock layer
        urgency: SystemNotifications.Notification.Critical
    }

    SystemNotifications.Notification {
        id: settingChangeNotif

        function reset(control) {
            previewBody = control.checked
                      //: Indicates a feature is now turned off. %1 = name of feature
                      //% "%1 disabled"
                    ? qsTrId("lipstick_jolla_home-la-toggle_disabled").arg(control.name)
                      //: Indicates a feature is now turned on. %1 = name of feature
                      //% "%1 enabled"
                    : qsTrId("lipstick_jolla_home-la-toggle_enabled").arg(control.name)
            icon = control.systemIcon
        }

        urgency: SystemNotifications.Notification.Critical
    }
}
