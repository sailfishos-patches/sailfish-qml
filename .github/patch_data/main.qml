import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

Page {
    id: page

    ConfigurationGroup {
        id: launcherViewSettings
        path: "/apps/lipstick-jolla-home-qt5/launcherView"
        property bool glassBackground: true
        property bool themedBackgroundColor: true
        property real backgroundOpacity: 0.9
    }

    ConfigurationGroup {
        id: launcherGridSettings
        path: "/apps/lipstick-jolla-home-qt5/launcherGrid"
        property int columns: 4
        property int rows: 6
        property int lcolumns: 4
        property int lrows: 4
        property bool editLabelVisible: true
        property bool zoomIcons: false
        property bool zoomFonts: false
        property real zoomValue: 1.0
    }

    ConfigurationGroup {
        id: launcherSettings
        path: "/apps/lipstick-jolla-home-qt5/launcher"
        property bool freeScroll: true
        property bool useScroll: true
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        VerticalScrollDecorator {}

        Column {
            id: content
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Launcher settings")
            }

            SectionHeader {
                text: qsTr("Grid portrait")
            }

            Slider {
                width: parent.width
                label: qsTr("Columns count")
                maximumValue: 10
                minimumValue: 2
                stepSize: 1
                value: launcherGridSettings.columns
                valueText: value

                onReleased: launcherGridSettings.columns = Math.round(value)
            }

            Slider {
                width: parent.width
                label: qsTr("Rows count")
                maximumValue: 10
                minimumValue: 2
                stepSize: 1
                value: launcherGridSettings.rows
                valueText: value

                onValueChanged: launcherGridSettings.rows = Math.round(value)
            }

            SectionHeader {
                text: qsTr("Grid landscape")
            }

            Slider {
                width: parent.width
                label: qsTr("Columns count")
                maximumValue: 10
                minimumValue: 2
                stepSize: 1
                value: launcherGridSettings.lcolumns
                valueText: value

                onReleased: launcherGridSettings.lcolumns = Math.round(value)
            }

            Slider {
                width: parent.width
                label: qsTr("Rows count")
                maximumValue: 10
                minimumValue: 2
                stepSize: 1
                value: launcherGridSettings.lrows
                valueText: value

                onValueChanged: launcherGridSettings.lrows = Math.round(value)
            }

            SectionHeader {
                text: qsTr("Common")
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Change font size")
                checked: launcherGridSettings.zoomFonts
                onClicked: launcherGridSettings.zoomFonts = checked
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Change icons size")
                checked: launcherGridSettings.zoomIcons
                onClicked: launcherGridSettings.zoomIcons = checked
            }

            Slider {
                width: parent.width
                label: qsTr("Zoom value")
                maximumValue: 200
                minimumValue: 40
                stepSize: 1
                value: launcherGridSettings.zoomValue * 100
                valueText: parseInt(value) + "%"

                onValueChanged: launcherGridSettings.zoomValue = value / 100.0
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Show labels in edit mode")
                checked: launcherGridSettings.editLabelVisible
                onClicked: launcherGridSettings.editLabelVisible = checked
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Scroll without pages")
                checked: launcherSettings.freeScroll
                onClicked: launcherSettings.freeScroll = checked
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Show scrollbar")
                checked: launcherSettings.useScroll
                visible: launcherSettings.freeScroll
                onClicked: launcherSettings.useScroll = checked
            }

            SectionHeader {
                text: qsTr("Background")
            }

            TextSwitch {
                width: parent.width
                text: qsTr("Use themed background")
                checked: launcherViewSettings.glassBackground
                onClicked: launcherViewSettings.glassBackground = checked
            }

            TextSwitch {
                visible: !launcherViewSettings.glassBackground
                width: parent.width
                text: qsTr("Use system color background")
                checked: launcherViewSettings.themedBackgroundColor
                onClicked: launcherViewSettings.themedBackgroundColor = checked
            }

            Slider {
                width: parent.width
                label: qsTr("Background opacity")
                maximumValue: 100
                minimumValue: 0
                stepSize: 1
                value: launcherViewSettings.backgroundOpacity * 100
                valueText: parseInt(value) + "%"

                onValueChanged: launcherViewSettings.backgroundOpacity = value / 100.0
            }
        }
    }
}
