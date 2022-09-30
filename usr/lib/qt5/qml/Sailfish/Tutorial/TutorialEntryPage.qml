/*
 * Copyright (c) 2014 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Nemo.Configuration 1.0

MainPage {
    id: root

    property bool allowSystemGesturesBetweenLessons

    property bool _tutorialStarted
    property bool configurePeek: _tutorialStarted && !!_window
    property QtObject _window

    onStatusChanged: {
        if (status === PageStatus.Active) {
            // Don't override window and application window properties
            // before the tutorial really starts.
            _tutorialStarted = true
        }
    }

    onConfigurePeekChanged: {
        if (configurePeek) {
            _window.PeekFilter.pressDelay = 200
            _window.PeekFilter.threshold = Screen.width / 4
            _window.PeekFilter.boundaryWidth = peekFilterConfigs.boundaryWidth
            _window.PeekFilter.boundaryHeight = peekFilterConfigs.boundaryHeight
        }
    }

    // Default to disable back navigation
    backNavigation: false

    Connections {
        target: __silica_applicationwindow_instance
        onWindowChanged: {
            root._window = window
        }
    }

    ConfigurationGroup {
        id: peekFilterConfigs
        path: "/desktop/lipstick-jolla-home/peekfilter"
        property int boundaryWidth: Theme.paddingLarge
        property int boundaryHeight: Theme.paddingLarge
    }
}
