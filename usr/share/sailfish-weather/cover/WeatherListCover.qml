import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Weather 1.0

Item {
    id: root

    property int visibleItemCount: 4
    property int maximumHeight: parent.height - Theme.itemSizeSmall/2
    property int itemHeight: Math.round(maximumHeight / visibleItemCount)

    PathView {
        id: view

        property int rollIndex
        property real rollOffset

        x: Theme.paddingLarge
        model: savedWeathersModel
        width: parent.width - 2*x
        pathItemCount: count > 4 ? 5 : Math.min(visibleItemCount, count)
        height: Math.min(visibleItemCount, count)/visibleItemCount*maximumHeight
        offset: rollIndex + rollOffset
        delegate: WeatherCoverItem {
            property bool aboutToSlideIn: view.rollOffset === 0 && model.index === (view.count - view.rollIndex) % view.count

            width: view.width
            visible: view.count <= 4 || !aboutToSlideIn
            topPadding: Theme.paddingLarge + Theme.paddingMedium
            text: model.status === Weather.Error ? model.city : TemperatureConverter.format(model.temperature) + " " + model.city
            //% "Loading failed"
            description: model.status === Weather.Error ? qsTrId("weather-la-loading_failed") : model.description
        }
        path: Path {
            startX: view.width/2; startY: view.count > 4 ? -itemHeight/2 : itemHeight/2
            PathLine { x: view.width/2; y: view.height + (view.count > 4 ? itemHeight/2 : itemHeight/2) }
        }
        Binding {
            when: view.count <= 4
            target: view
            property: "offset"
            value: 0
        }
        SequentialAnimation on rollOffset {
            id: rollAnimation
            running: cover.status === Cover.Active && view.visible && view.count > 4
            loops: Animation.Infinite
            NumberAnimation {
                from: 0
                to: 1
                duration: 1000
                easing.type: Easing.InOutQuad
            }
            ScriptAction {
                script: {
                    view.rollIndex = view.rollIndex + 1
                    view.rollOffset = 0
                    if (view.rollIndex >= view.count) {
                        view.rollIndex = 0
                    }
                }
            }
            PauseAnimation { duration: 3000 }
        }
    }
    OpacityRampEffect {
        enabled: view.count > 3
        sourceItem: root
        parent: root.parent
        direction: OpacityRamp.TopToBottom
        slope: 3
        offset: 1 - 1 / slope
    }
}

