/*
 * Copyright (c) 2019 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.lipstick 0.1

BlurredBackground {
    function combinedOverlayColor(dimmingColor, dimmingOpacity, highlightColor, highlightOpacity) {
        return Theme.rgba(
                    Qt.tint(dimmingColor, Theme.rgba(highlightColor, highlightOpacity)),
                    1 - ((1 - dimmingOpacity) * (1 - highlightOpacity)))
    }

    sourceItem: Lipstick.compositor.dialogBlurSource

    color: palette.colorScheme === Theme.LightOnDark
            ? combinedOverlayColor("black", 0.3, palette.highlightBackgroundColor, 0.4)
            : combinedOverlayColor("white", 0.7, palette.highlightBackgroundColor, 0.3)

    radius: Theme.paddingLarge
}
