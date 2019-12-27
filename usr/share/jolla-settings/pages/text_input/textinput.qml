import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
import com.jolla.keyboard 1.0
import com.jolla.keyboard.translations 1.0
import org.nemomobile.notifications 1.0 as SystemNotifications
import org.nemomobile.dbus 2.0


Page {
    id: root

    property bool pinyinEnabled
    property bool emojisEnabled

    LayoutModel {
        id: layoutModel
    }

    ListModel {
        id: enabledLayoutModel

        property bool updating

        function getLayoutIndex(name) {
            for (var i = 0; i < count; ++i) {
                if (get(i).layout === name) {
                    return i
                }
            }
            return -1
        }

        function refresh() {
            updating = true
            var enabledLayouts = new Array
            var pinyinFound = false
            var emojisFound = false

            for (var i = 0; i < layoutModel.count; ++i) {
                var item = layoutModel.get(i)
                if (item.enabled) {
                    enabledLayouts.push({"name": item.name, "layout": item.layout})
                    if (item.type === "china_pinyin") {
                        pinyinFound = true
                    }
                    if (item.type === "emojis") {
                        emojisFound = true
                    }
                }
            }

            for (i = 0; i < enabledLayouts.length && i < count; ++i) {
                set(i, enabledLayouts[i])
            }
            if (enabledLayouts.length > count) {
                for (i = count; i < enabledLayouts.length; ++i) {
                    append(enabledLayouts[i])
                }
            } else {
                while (enabledLayouts.length < count) {
                    remove(count-1)
                }
            }

            root.pinyinEnabled = pinyinFound
            root.emojisEnabled = emojisFound

            // wait until ComboBox has updated its internal state
            refreshTimer.restart()
        }
    }

    ListModel {
        id: physicalLayouts

        ListElement {
            layout: "cz"
            name: "Čeština"
        }
        ListElement {
            layout: "dk"
            name: "Dansk"
        }
        ListElement {
            layout: "de"
            name: "Deutsch"
        }
        ListElement {
            layout: "ee"
            name: "Eesti"
        }
        ListElement {
            layout: "us"
            name: "English (US)"
        }
        ListElement {
            layout: "gb"
            name: "English (UK)"
        }
        ListElement {
            layout: "es"
            name: "Español"
        }
        ListElement {
            layout: "fr"
            name: "Français"
        }
        ListElement {
            layout: "is"
            name: "Íslensku"
        }
        ListElement {
            layout: "it"
            name: "Italiano"
        }
        ListElement {
            layout: "hu"
            name: "Magyar"
        }
        ListElement {
            layout: "nl"
            name: "Nederlands"
        }
        ListElement {
            layout: "no"
            name: "Norsk"
        }
        ListElement {
            layout: "pl"
            name: "Polski"
        }
        ListElement {
            layout: "pt"
            name: "Português"
        }
        ListElement {
            layout: "si"
            name: "Slovenščina"
        }
        ListElement {
            layout: "fi"
            name: "Suomi"
        }
        ListElement {
            layout: "se"
            name: "Svenska"
        }
        ListElement {
            layout: "ch"
            name: "Swiss"
        }
        ListElement {
            layout: "tr"
            name: "Türkçe"
        }
        ListElement {
            layout: "kz"
            name: "Қазақ"
        }
        ListElement {
            layout: "ru"
            name: "Русский"
        }

        function indexOf(layout) {
            for (var i = 0; i < count; ++i) {
                if (get(i).layout === layout) {
                    return i
                }
            }

            return -1
        }
    }

    SystemNotifications.Notification {
        id: systemNotification
        isTransient: true
        //: System notification advising user who is trying to disable all the keyboard layouts
        //% "You must have at least one keyboard selected"
        previewBody: qsTrId("settings_text_input-he-warning_too_few_keyboards")
    }

    Timer {
        id: refreshTimer
        interval: 1
        onTriggered: {
            layoutComboBox.currentIndex = enabledLayoutModel.getLayoutIndex(currentLayoutConfig.value)
            enabledLayoutModel.updating = false
        }
    }

    Component {
        id: enabledKeyboardsPage
        Page {
            SilicaListView {
                anchors.fill: parent
                header: PageHeader {
                    //: Page header in enabled keyboards settings page
                    //% "Keyboards"
                    title: qsTrId("settings_text_input-he-enabled_keyboards")
                }
                model: layoutModel
                delegate: TextSwitch {
                    width: ListView.view.width
                    height: Theme.itemSizeSmall
                    text: qsTrId(name)

                    checked: layoutModel.get(index).enabled
                    automaticCheck: false
                    onClicked: {
                        if (checked && layoutModel.enabledCount === 1) {
                            systemNotification.publish()
                        } else if (checked && layoutModel.enabledCount === 2
                                   && emojisEnabled && type !== "emojis") {
                            systemNotification.publish()
                        } else {
                            systemNotification.close()
                            checked = !checked
                            layoutModel.setEnabled(index, checked)
                        }
                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }

    DBusInterface {
        id: keyboardDbus
        service: "com.jolla.keyboard"
        path: "/com/jolla/keyboard"
        iface: "com.jolla.keyboard"
    }

    SilicaFlickable {
        id: listView

        anchors.fill: parent
        contentHeight: content.height + Theme.paddingMedium

        Column {
            id: content

            width: parent.width

            PageHeader {
                //% "Text input"
                title: qsTrId("settings_text_input-he-text_input")
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

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            ButtonLayout {
                preferredWidth: Theme.buttonWidthMedium
                Button {
                    //: Shows list view for selecting active keyboards
                    //% "Keyboards"
                    text: qsTrId("settings_text_input-bt-enabled_keyboards")
                    onClicked: pageStack.animatorPush(enabledKeyboardsPage)
                }

                Button {
                    ButtonLayout.newLine: true

                    //% "Clear learned words"
                    text: qsTrId("settings_text_input-bt-clear_words")
                    onClicked: {
                        //% "Cleared learned words"
                        Remorse.popupAction(root, qsTrId("settings_text_input-la-cleared_words_remorse_banner"),
                                        function() {
                                            keyboardDbus.call("clearData", undefined)
                                        })
                    }
                }
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            SectionHeader {
                visible: root.pinyinEnabled
                //% "Chinese virtual keyboard"
                text: qsTrId("settings_text_input-la-chinese_virtual_keyboard_section")
            }

            TextSwitch {
                visible: root.pinyinEnabled
                automaticCheck: false
                checked: mohuConfig.value
                //: Aka "mohu"
                //% "Fuzzy pinyin"
                text: qsTrId("settings_text_input-la-fuzzy_pinyin")
                onClicked: mohuConfig.value = !mohuConfig.value
            }

            SectionHeader {
                //% "Hardware keyboards"
                text: qsTrId("setings_text_input-la-hardware_keyboards_section")
            }

            ComboBox {
                id: hwLayoutComboBox

                width: parent.width
                //: Active physical keyboard layout combobox in settings
                //% "Active layout"
                label: qsTrId("settings_text_input-bt-active_physical_keyboard")

                menu: ContextMenu {
                    Repeater {
                        model: physicalLayouts
                        delegate: MenuItem {
                            text: name
                        }
                    }
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0) {
                        currentPhysicalLayoutConfig.value = physicalLayouts.get(currentIndex).layout
                    }
                }

                Binding {
                    target: hwLayoutComboBox
                    property: "currentIndex"
                    value: physicalLayouts.indexOf(currentPhysicalLayoutConfig.value)
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
        onValueChanged: enabledLayoutModel.refresh()
    }

    ConfigurationValue {
        id: mohuConfig

        key: "/sailfish/text_input/mohu_enabled"
        defaultValue: false
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

    Component.onCompleted: enabledLayoutModel.refresh()
}
