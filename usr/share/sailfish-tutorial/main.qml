/*
 * Copyright (c) 2014 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Tutorial 1.0
import Nemo.Configuration 1.0

ApplicationWindow {
    // Keeps Gallery PhotosPage in portrait
    allowedOrientations: Orientation.Portrait

    property alias globalColorScheme: colorScheme.value

    initialPage: Component {
        TutorialEntryPage {
            allowSystemGesturesBetweenLessons: true
        }
    }

    cover: Component {
        CoverBackground {
            CoverPlaceholder {
                //% "Tutorial"
                text: qsTrId("tutorial-ap-name")
                textColor: globalColorScheme === Theme.DarkOnLight ? Theme.darkSecondaryColor : Theme.lightSecondaryColor
                icon.source: "image://theme/icon-launcher-tutorial"
            }
        }
    }

    ConfigurationValue {
        id: colorScheme
        key: "/desktop/jolla/theme/color_scheme"
    }
}

