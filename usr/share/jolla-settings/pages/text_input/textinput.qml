/****************************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2020 Open Mobile Platform LLC.
** All rights reserved.
**
** This file is part of Jolla Keyboard UI component package.
**
** You may use this file under the terms of the GNU Lesser General
** Public License version 2.1 as published by the Free Software Foundation
** and appearing in the file license.lgpl included in the packaging
** of this file.
**
** This library is free software; you can redistribute it and/or
** modify it under the terms of the GNU Lesser General Public
** License version 2.1 as published by the Free Software Foundation
** and appearing in the file license.lgpl included in the packaging
** of this file.
**
** This library is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
** Lesser General Public License for more details.
**
****************************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import com.jolla.keyboard 1.0
import com.jolla.keyboard.translations 1.0

Page {
    id: root

    LayoutModel {
        id: layoutModel
    }

    PhysicalLayoutModel {
        id: physicalLayoutModel
        onEnabledLayoutsChanged: enabledPhysicalLayoutModel.refresh()
    }

    ListModel {
        id: pluginSettingsModel

        function refresh() {
            var layoutSettings = new Array

            for (var i = 0; i < layoutModel.count; ++i) {
                var item = layoutModel.get(i)

                if (item.enabled && item.settings &&
                        layoutSettings.indexOf(item.settings) === -1) {
                    layoutSettings.push(item.settings)
                }
            }

            for (i = 0; i < layoutSettings.length; ++i) {
                var value = {"settingsSource": layoutSettings[i]}

                if (i < count) {
                    set(i, value)
                } else {
                    append(value)
                }
            }

            if (layoutSettings.length < count) {
                remove(layoutSettings.length, count - layoutSettings.length)
            }
        }
    }

    EnabledLayoutModel {
        id: enabledLayoutModel
        layoutModel: layoutModel
        refreshTimer.onTriggered: {
            layoutComboBox.currentIndex = enabledLayoutModel.getLayoutIndex(currentLayoutConfig.value)
            enabledLayoutModel.updating = false
        }
    }

    EnabledLayoutModel {
        id: enabledPhysicalLayoutModel
        layoutModel: physicalLayoutModel
        refreshTimer.onTriggered: {
            physicalLayoutComboBox.currentIndex = enabledPhysicalLayoutModel.getLayoutIndex(currentPhysicalLayoutConfig.value)
            enabledPhysicalLayoutModel.updating = false
        }
    }

    Component {
        id: enabledKeyboardsPage
        KeyboardsPage {
            model: layoutModel
            emojisEnabled: enabledLayoutModel.emojisEnabled
        }
    }

    Component {
        id: enabledPhysicalLayoutsPage
        KeyboardsPage {
            model: physicalLayoutModel
        }
    }

    SilicaFlickable {
        id: listView

        anchors.fill: parent
        contentHeight: content.height + Theme.paddingMedium

        Column {
            id: content
            width: parent.width

            function getEnabledLayoutsDisplayValue(model) {
                var result = []
                var max = 5
                for (var i = 0; i < model.count; i++) {
                    var layout = model.get(i)
                    if (layout.enabled) {
                        if (result.length < max) {
                            result.push(qsTrId(layout.name))
                        } else {
                            result.push("…")
                            break
                        }
                    }
                }
                return result.join(Format.listSeparator)
            }

            PageHeader {
                //% "Text input"
                title: qsTrId("settings_text_input-he-text_input")
            }

            ValueButton {
                //% "Keyboards"
                label: qsTrId("settings_text_input-bt-enabled_keyboards")
                value: content.getEnabledLayoutsDisplayValue(layoutModel)
                onClicked: pageStack.animatorPush(enabledKeyboardsPage)
            }

            ComboBox {
                id: layoutComboBox

                width: parent.width
                //: Active layout combobox in settings
                //% "Active keyboard"
                label: qsTrId("settings_text_input-bt-active_keyboard")
                //% "You can also change the active keyboard quickly by dragging horizontally between the keyboards, "
                //% "or pressing the spacebar of keyboard until language options appear, moving your finger on top "
                //% "of the option you want to choose and releasing your finger."
                description: qsTrId("settings_text_input-la-keyboard_change_hint")

                menu: ContextMenu {
                    Repeater {
                        model: enabledLayoutModel
                        delegate: MenuItem {
                            text: qsTrId(name)
                        }
                    }
                }

                onCurrentIndexChanged: {
                    if (!enabledLayoutModel.updating && currentIndex >= 0) {
                        currentLayoutConfig.value = enabledLayoutModel.get(currentIndex).layout
                    }
                }

                Binding {
                    target: layoutComboBox
                    property: "currentIndex"
                    value: enabledLayoutModel.getLayoutIndex(currentLayoutConfig.value)
                }
            }

            TextSwitch {
                automaticCheck: false
                checked: splitConfig.value
                //% "Allow splitting keyboard in landscape orientation"
                text: qsTrId("settings_text_input-la-split_keyboard")
                onClicked: splitConfig.value = !splitConfig.value
            }

            Repeater {
                model: pluginSettingsModel
                delegate: Component {
                    Loader {
                        width: parent.width
                        source: settingsSource
                    }
                }
            }

            SectionHeader {
                //% "Hardware keyboards"
                text: qsTrId("setings_text_input-la-hardware_keyboards_section")
            }

            ValueButton {
                //% "Layouts"
                label: qsTrId("settings_text_input-bt-enabled_hardware_keyboard_layouts")
                value: content.getEnabledLayoutsDisplayValue(physicalLayoutModel)
                onClicked: pageStack.animatorPush(enabledPhysicalLayoutsPage)
            }

            ComboBox {
                id: physicalLayoutComboBox

                width: parent.width
                //: Active layout combobox in settings
                //% "Active keyboard layout"
                label: qsTrId("settings_text_input-bt-active_hardware_keyboard_layout")
                //% "You can also change the active keyboard layout quickly by pressing Ctrl+Space."
                description: qsTrId("settings_text_input-la-hardware_keyboard_layout_change_hint")

                menu: ContextMenu {
                    Repeater {
                        model: enabledPhysicalLayoutModel
                        delegate: MenuItem {
                            text: name
                        }
                    }
                }

                onCurrentIndexChanged: {
                    if (!enabledPhysicalLayoutModel.updating && currentIndex >= 0) {
                        currentPhysicalLayoutConfig.value = enabledPhysicalLayoutModel.get(currentIndex).layout
                    }
                }

                Binding {
                    target: physicalLayoutComboBox
                    property: "currentIndex"
                    value: enabledPhysicalLayoutModel.getLayoutIndex(currentPhysicalLayoutConfig.value)
                }
            }
        }
    }

    ConfigurationValue {
        id: currentLayoutConfig
        key: "/sailfish/text_input/active_layout"
    }

    ConfigurationValue {
        id: activeLayoutsConfig
        key: "/sailfish/text_input/enabled_layouts"
        onValueChanged: {
            pluginSettingsModel.refresh()
            enabledLayoutModel.refresh()
        }
    }

    ConfigurationValue {
        id: splitConfig

        key: "/sailfish/text_input/split_landscape"
        defaultValue: false
    }

    ConfigurationValue {
        id: currentPhysicalLayoutConfig
        key: "/desktop/lipstick-jolla-home/layout"
        defaultValue: "us"
    }

    Component.onCompleted: {
        pluginSettingsModel.refresh()
        enabledLayoutModel.refresh()
        enabledPhysicalLayoutModel.refresh()
    }
}
