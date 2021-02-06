/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica.private 1.0

GlassBlur {
    size { width: 192; height: 192 }

    saturationMultiplier: 1.4
    valueMultiplier: 0.85
    valueOffset: 0

    deviation: 4.25
    repetitions: 3
}
