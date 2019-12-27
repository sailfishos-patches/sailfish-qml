import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1

Item {
    id: blurSource
    default property alias _data: content.data
    property alias blur: blurEffect.blur
    property alias provider: blurEffect

    function update() {
        if (blur && !compositedItem.live) {
            compositedItem.scheduleUpdate()
        }
    }

    Item {
        id: content
        width: blurSource.width
        height: blurSource.height
    }

    ShaderEffectSource {
        id: compositedItem

        width: blurSource.width
        height: blurSource.height

        sourceItem: blurEffect.blur ? content : null
        hideSource: Desktop.settings.live_snapshots
        live: Desktop.settings.live_snapshots
        visible: Desktop.settings.live_snapshots
    }


    SilicaPrivate.BlurEffect {
        id: blurEffect

        iterations: Desktop.settings.blur_iterations
        kernel: Desktop.settings.blur_kernel
        levels: Desktop.settings.blur_levels
        deviation: Desktop.settings.blur_deviation
        iterationBehavior: Desktop.settings.blur_iteration_behavior
        sourceItem: compositedItem

        onBlurChanged: blurSource.update()

        function update() {
            blurSource.update()
        }
    }
}
