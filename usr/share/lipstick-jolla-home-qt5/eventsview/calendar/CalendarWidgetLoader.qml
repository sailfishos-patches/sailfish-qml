/****************************************************************************
**
** Copyright (C) 2015 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import com.jolla.lipstick 0.1

Loader {
    property Item eventsView
    property string widgetFilePath: "/usr/lib/qt5/qml/Sailfish/Calendar/CalendarWidget.qml"
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

    Binding {
        target: item
        when: item
        property: "enableUpdates"
        value: eventsVisible
    }

    Connections {
        target: eventsView
        onShown: if (item) item.preventCollapse()
        onPeeked: if (item) item.preventCollapse()
        onDeactivated: if (item) item.collapse()
        onScreenLocked: if (item) item.collapse()
        onScreenBlanked: if (item) item.collapse()
    }

    FileUtils { id: fileUtils }
}
