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
    sourceItem: Lipstick.compositor.dialogBlurSource
    color: Theme.rgba(Theme.highlightBackgroundColor, Theme.opacityHigh)
    radius: Theme.paddingLarge
}
