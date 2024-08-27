/****************************************************************************
 **
 ** Copyright (C) 2013-2015 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import org.nemomobile.lipstick 0.1

Private.SwipeItem {
    id: root

    property real contentLeftMargin: Theme.horizontalPageMargin
    property alias roundedCorners: background.roundedCorners
    property bool userRemovable: true
    property bool groupHighlighted

    signal removeRequested
    signal triggered

    default property alias _content: content.data
    readonly property bool housekeeping: Lipstick.compositor.eventsLayer.housekeeping

    // Fade out item in housekeeping mode, if not removable
    property real _baseOpacity: housekeeping && !userRemovable ? Theme.opacityLow : 1.0
    property real _animatedOpacity: 1
    property bool extraBackgroundPadding
    property bool _suppressPressEffect // hide remaining pressEffect when going into housekeeping
    property bool _actionPending

    opacity: _baseOpacity * _animatedOpacity
    draggable: housekeeping && userRemovable
    highlighted: ((enabled && down && !showSwipeHint && !_suppressPressEffect) || groupHighlighted)

    Behavior on _baseOpacity {
        FadeAnimation { property: "_baseOpacity"; duration: 200 }
    }

    onSwipedAway: removeRequested()
    onDraggableChanged: if (draggable) _suppressPressEffect = true

    onPressed: _suppressPressEffect = false

    onPressAndHold: {
        if (!housekeeping) {
            Lipstick.compositor.eventsLayer.setHousekeeping(true)
        }
    }

    onClicked: {
        if (housekeeping) {
            Lipstick.compositor.eventsLayer.setHousekeeping(false)
            return
        }
        if (Lipstick.compositor.lockScreenLayer.lockScreenEventsEnabled) {
            Lipstick.compositor.unlock()
            _actionPending = true
        } else {
            root.triggered()
        }
    }

    Connections {
        target: Lipstick.compositor.lockScreenLayer
        onDeviceIsLockedChanged: {
            if (_actionPending && !Lipstick.compositor.lockScreenLayer.deviceIsLocked) {
                root.triggered()
                _actionPending = false
            }
        }
        onShowingLockCodeEntryChanged: {
            if (!Lipstick.compositor.lockScreenLayer.showingLockCodeEntry) {
                _actionPending = false
            }
        }
    }

    _showPress: down && !housekeeping

    Private.BannerBackground {
        id: background

        z: -1
        parent: root.contentItem
        highlighted: root.draggable && root.highlighted
        height: parent.height - (extraBackgroundPadding ? 0 : 2*y)
        x: Theme.paddingMedium
        y: Math.round(Theme.paddingSmall/2)
        width: parent.width - 2*x
        enabled: root.draggable

        color:  Theme.highlightBackgroundColor
        opacity: enabled ? Theme.highlightBackgroundOpacity : 0.0

        Behavior on opacity { FadeAnimator {} }
    }

    Item {
        id: content

        parent: contentItem
        width: parent.width - x - Theme.horizontalPageMargin
        height: parent.height
        x: root.contentLeftMargin
    }
}
