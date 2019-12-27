import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings 1.0
import org.nemomobile.lipstick 0.1

SettingsControl {
    id: root

    property alias iconSource: settingIcon.source
    property url pageSource
    property bool useHighlightColor: true

    property int __lipstick_favorite_settings_item

    signal triggered()

    contentHeight: Theme.itemSizeSmall + label.height
    _showPress: false

    menu: null  // actions and page settings do not have context menus
    privileged: true    // triggering of actions and page settings require unlocked device
    settingsPageEntryPath: entryPath

    onClicked: {
        if (Lipstick.compositor.topMenuLayer.housekeeping) {
            return
        }
        if (userAccessRestricted) {
            root.requestUserAccess()
        } else {
            root.triggered()
        }
    }

    HighlightImage {
        id: settingIcon
        anchors {
            centerIn: parent
            verticalCenterOffset: -Theme.paddingSmall
        }

        highlighted: root.highlighted
    }

    Label {
        id: label
        truncationMode: TruncationMode.Fade
        color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: settingIcon.bottom
            topMargin: Theme.paddingSmall
        }
        width: root.width - Theme.paddingSmall * 2
        height: Math.round(implicitHeight + Theme.fontSizeTiny * 1.3)
        font.pixelSize: Theme.fontSizeTiny
        horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
        text: root.shortName.length > 0 ? root.shortName : root.name
    }
}
