/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1

Loader {
    id: loader

    property Item eventsView
    property string widgetFilePath: StandardPaths.resolveImport("Sailfish.Calendar.CalendarWidget")
    property bool widgetExists: fileUtils.exists(widgetFilePath)
    property bool eventsVisible: eventsViewVisible

    width: parent.width
    height: item ? item.height : 0
    asynchronous: true
    visible: status === Loader.Ready

    onEventsVisibleChanged: {
        widgetExists = fileUtils.exists(widgetFilePath)
    }
    onWidgetExistsChanged: {
        if (widgetExists && status === Loader.Null) {
            source = widgetFilePath
        } else if (!widgetExists) {
            source = ""
        }
    }

    states: State {
        when: loader.status == Loader.Ready
        PropertyChanges {
            target: loader.item
            enableUpdates: eventsVisible
            deviceLocked: Lipstick.compositor.lockScreenLayer.lockScreenEventsEnabled
        }
    }

    Connections {
        target: eventsView
        onShown: if (item) item.preventCollapse()
        onPeeked: if (item) item.preventCollapse()
        onScreenLocked: if (item) item.collapse()
        onScreenBlanked: if (item) item.collapse()
    }

    Connections {
        target: Lipstick.compositor.lockScreenLayer
        onDeviceIsLockedChanged: {
            if (loader.item && !Lipstick.compositor.lockScreenLayer.deviceIsLocked) {
                loader.item.checkPendingAction()
            }
        }
        onShowingLockCodeEntryChanged: {
            if (loader.item && !Lipstick.compositor.lockScreenLayer.showingLockCodeEntry) {
                loader.item.cancelPendingAction()
            }
        }
    }

    Connections {
        target: loader.item
        onRequestUnlock: Lipstick.compositor.unlock()
    }

    Connections {
        target: Lipstick.compositor.eventsLayer
        onDeactivated: if (item) item.collapse()
    }

    FileUtils { id: fileUtils }
}
