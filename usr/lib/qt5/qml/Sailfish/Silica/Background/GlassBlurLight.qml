/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica.private 1.0

GlassBlur {
    size { width: 128; height: 128 }

    saturationMultiplier: 1.4
    valueMultiplier: 1.6
    valueOffset: 0.35

    deviation: 4
    repetitions: 4
}
