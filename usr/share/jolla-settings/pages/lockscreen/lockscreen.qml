import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.lipstick 0.1

Page {
    id: page

    property int _maxNumberOfShortcuts: 3

    SilicaFlickable {

        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content

            width: parent.width
            spacing: Theme.paddingMedium

            Column {
                width: parent.width
                PageHeader {
                    //% "Lock screen"
                    title: qsTrId("settings_display-he-lockscreen")
                }
                SectionHeader {
                    //% "Pulley menu"
                    text: qsTrId("settings_shortcuts-la-pulley_menu")
                }
            }

            Label {
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: parent.right
                    rightMargin: Theme.paddingLarge
                }
                opacity: Theme.opacityHigh
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                //% "You can have shortcuts to your favorite apps from Lock Screen. Select up to %n shortcuts which are then available in the Pulley Menu."
                //: Takes max number of shortcuts as a parameter.
                text: qsTrId("settings_shortcuts-la-lock_screen_hint", _maxNumberOfShortcuts)
            }

            Item { width: 1; height: Theme.paddingMedium }

            SectionHeader {
                //% "Select shortcuts"
                text: qsTrId("settings_shortcuts-la-select_shortcuts")
            }

            Item {
                width: content.width
                height: Theme.itemSizeMedium + Theme.paddingMedium

                ShortcutItem {
                    width: parent.width
                    enabled: lockScreenShortcuts.count < _maxNumberOfShortcuts
                    //% "Add shortcut"
                    title: qsTrId("settings_shortcuts-la-lock_screen_shortcut_add")
                    actionIconSource: "icon-m-add"
                    onClicked: pageStack.animatorPush(appSelector)
                }
            }

            Repeater {
                id: shortcutRepeater

                model: lockScreenShortcuts.value

                delegate: ShortcutItem {
                    id: shortcut

                    width: content.width
                    visible: model.index < _maxNumberOfShortcuts
                    title: {
                        var item
                        if (lockScreenShortcuts.isDesktopFile(modelData)) {
                            item = applicationModel.itemForFilePath(modelData)
                        }
                        return item ? item.title : ''
                    }
                    actionIconSource: "icon-m-clear"
                    onClicked: removeAnimation.start()

                    RemoveAnimation {
                        id: removeAnimation

                        target: shortcut
                        onStopped: lockScreenShortcuts.removeValue(modelData)
                    }
                }
            }
        }

        VerticalScrollDecorator {}
    }

    ConfigurationValue {
        id: lockScreenShortcuts

        property int count: value.length

        property var desktopFiles: {
            var files = []
            for (var i = 0; i < value.length; ++i) {
                if (isDesktopFile(value[i])) {
                    files.push(value[i])
                }
            }
            return files
        }

        function isDesktopFile(path) {
            return (path.lastIndexOf(".desktop") == path.length - 8)
        }

        key: "/desktop/lipstick-jolla-home/lock_screen_shortcuts"
        defaultValue: []

        function updateValue(val, replace) {
            var insertIndex = 0
            var removeCount = 0
            var i = replace ? value.indexOf(replace) : -1
            if (i != -1) {
                if (val == replace)
                    return

                insertIndex = i
                removeCount = 1
            }

            var newShortcuts = value.slice(0)
            newShortcuts.splice(insertIndex, removeCount, val)
            value = newShortcuts
        }

        function removeValue(val) {
            var i = value.indexOf(val)
            if (i != -1) {
                var newShortcuts = value.slice(0)
                newShortcuts.splice(i, 1)
                value = newShortcuts
            }
        }

        function containsValue(val) {
            return value.indexOf(val) != -1
        }
    }

    LauncherWatcherModel {
        id: applicationModel

        function itemForFilePath(path) {
            for (var i = 0; i < itemCount; ++i) {
                var item = get(i)
                if (item.filePath == path) {
                    return item
                }
            }
        }

        filePaths: lockScreenShortcuts.desktopFiles
    }

    Component {
        id: appSelector

        ApplicationSelectionPage {
            selections: lockScreenShortcuts.value
            onSelected: lockScreenShortcuts.updateValue(filePath, originalFilePath)
        }
    }
}
