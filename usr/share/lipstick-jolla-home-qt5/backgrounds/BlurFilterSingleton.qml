/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica.Background 1.0
import Sailfish.Ambience 1.0
import com.jolla.lipstick 0.1

GlassBlur {
    repetitions: Desktop.settings.blur_iterations
    sampleSize: Desktop.settings.blur_kernel
    deviation: Desktop.settings.blur_deviation
}
