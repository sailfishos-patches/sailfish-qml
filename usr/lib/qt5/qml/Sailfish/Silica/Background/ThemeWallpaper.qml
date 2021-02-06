/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.Background 1.0

FilteredImage {
    property int colorScheme: palette.colorScheme
    property string wallpaperFilter: Theme._wallpaperFilter
    property list<QtObject> explicitFilters

    filtering: true
    filters: explicitFilters.length > 0
            ? explicitFilters
            : [ Filters[(wallpaperFilter !== "" ? wallpaperFilter : "glassBlur") + [ "Dark", "Light" ][colorScheme]]
                || Filters[wallpaperFilter]
                || Filters.glassBlur
            ]
}
