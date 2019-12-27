import QtQuick 2.2
import QtQuick.Window 2.2 as QtQuick

Item {
    id: layersParent
    property alias launcherInteractiveArea: launcherArea
    property alias topMenuInteractiveArea: topMenuArea
    property alias cameraInteractiveArea: cameraArea

    default property alias _data: cameraArea.data
    property int orientationAngle
    readonly property bool _portrait: (orientationAngle % 180) == 0

    MouseArea {
        id: launcherArea

        objectName: "LayersParent_launcherArea"
        anchors.fill: layersParent
        enabled: drag.target && drag.target.peekFilter.enabled

        drag {
            filterChildren: true
            axis: _portrait ? Drag.YAxis : Drag.XAxis
            threshold: QtQuick.Screen.pixelDensity * 3 // 3mm

            minimumX: -width
            maximumX: width
            minimumY: -height
            maximumY: height
        }

        MouseArea {
            id: topMenuArea

            objectName: "LayersParent_topMenuArea"
            anchors.fill: launcherArea

            enabled: drag.target && drag.target.peekFilter.enabled
            drag {
                filterChildren: true
                axis: _portrait ? Drag.YAxis : Drag.XAxis
                threshold: QtQuick.Screen.pixelDensity * 3 // 3mm

                minimumX: -width
                maximumX: width
                minimumY: -height
                maximumY: height
            }

            MouseArea {
                id: cameraArea

                objectName: "LayersParent_cameraArea"
                anchors.fill: topMenuArea

                enabled: drag.target && drag.target.peekFilter.enabled
                drag.filterChildren: true
            }
        }
    }
}
