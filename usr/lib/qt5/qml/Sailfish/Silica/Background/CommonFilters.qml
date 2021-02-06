/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica.private 1.0

QtObject {
    id: filters

    property var filterNames: [ "glassBlur", "glassBlurDark", "glassBlurLight" ]

    property list<QtObject> objects
    default property alias _objects: filters.objects

    property SequenceFilterPrivate glassBlur: GlassBlur {
        saturationMultiplier: 1.5
    }

    property SequenceFilterPrivate glassBlurDark: GlassBlurDark {
    }

    property SequenceFilterPrivate glassBlurLight: GlassBlurLight {
    }
}
