import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
    id: diskUsageArea

    property bool initialized
    property alias model: repeater.model
    property real usedSpace
    property real totalSpace

    width: parent.width
    height: busyIndicator.height + 2 * Theme.paddingMedium

    DiskUsageCircle {
        id: circle
        anchors.centerIn: parent
        width: implicitWidth + Theme.paddingLarge
        value: usedSpace / totalSpace
        backgroundColor: Theme.rgba(Theme.primaryColor, Theme.backgroundHighlightOpacity)
        progressColor: "transparent"
    }

    DiskUsageCircle {
        id: busyIndicator

        value: 1/8
        anchors.centerIn: parent
        opacity: initialized ? 0.0 : 1.0
        backgroundColor: Theme.rgba(Theme.primaryColor, Theme.backgroundHighlightOpacity)
        progressColor: Theme.primaryColor

        Behavior on opacity { FadeAnimation { id: fadeAnimation }}
        RotationAnimator on rotation {
            from: 0; to: 360
            duration: 2000
            running: (!initialized || fadeAnimation.running) && busyIndicator.visible && Qt.application.active
            loops: Animation.Infinite
        }
    }

    DiskUsageLabelGroup {
        width: busyIndicator.width * 0.7
        anchors.centerIn: parent
        topLabelText: Format.formatFileSize(diskUsageArea.usedSpace)
        //% "Used"
        bottomLabelText: qsTrId("settings_storage-la-used")
    }

    Item {
        anchors.fill: busyIndicator
        opacity: initialized ? 1 : 0
        Behavior on opacity { FadeAnimation {} }
        anchors.centerIn: parent

        Repeater {
            id: repeater
            DiskUsageCircle {
                anchors.centerIn: parent
                backgroundColor: "transparent"
                progressColor: colors[model.index % colors.length]
                rotation: 360*model.position/repeater.model.total
                value: bytes/repeater.model.total
            }
        }
    }

    DiskUsageLabelGroup {
        anchors {
            left: circle.right
            leftMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }

        ruler.width: width*0.7
        horizontalAlignment: Text.AlignRight
        topLabelText: Format.formatFileSize(diskUsageArea.totalSpace - diskUsageArea.usedSpace)
        //% "Available"
        bottomLabelText: storageType == "user" ? qsTrId("settings_storage-la-available")
                                                //% "Free"
                                              : qsTrId("settings_storage-la-free")
    }
}
