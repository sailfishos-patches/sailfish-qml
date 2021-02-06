import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1
import "../backgrounds/filters" as F

Item {
    id: blurSource
    default property alias _data: content.data
    property alias blur: blurEffect.filtering
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

        sourceItem: blurEffect.filtering ? content : null
        hideSource: Desktop.settings.live_snapshots
        live: Desktop.settings.live_snapshots
        visible: Desktop.settings.live_snapshots
    }

    FilteredImage {
        id: blurEffect

        filters: F.BlurFilter

        sourceItem: compositedItem

        onFilteringChanged: blurSource.update()

        function update() {
            blurSource.update()
        }
    }
}
