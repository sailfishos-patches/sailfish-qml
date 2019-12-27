/****************************************************************************
**
** Copyright (C) 2014 Jolla Ltd.
** Contact: Joona Petrell <joona.petrell@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

ListItem {
    id: root

    property bool removeWhenHidden
    property bool active: eventsViewVisible
    signal close

    onClicked: {
        storeClientInterface.call("showApp", "sailfish-weather")
        removeWhenHidden = true
    }
    onActiveChanged: {
        if (!active && removeWhenHidden) {
            removeComponent.createObject(root)
            advertiseWeather = false
        }
    }
    menu: contextMenuComponent
    contentHeight: primaryLabel.height + secondaryLabel.height + Theme.paddingLarge + Theme.paddingMedium

    WeatherIcon {
        id: icon
        x: Theme.horizontalPageMargin
        y: Theme.paddingLarge
    }
    Label {
        id: primaryLabel

        //% "Get Weather application?"
        text: qsTrId("lipstick-jolla-home-la-weather_get_jolla_weather")
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeLarge
        wrapMode: Text.Wrap
        anchors {
            left: icon.right
            right: parent.right
            baseline: icon.verticalCenter
            leftMargin: Theme.paddingLarge
            rightMargin: Theme.horizontalPageMargin
        }
    }
    Label {
        id: secondaryLabel
        //% "Get your local Foreca powered Weather app straight to Events. Tap to see more."
        text: qsTrId("lipstick-jolla-home-la-weather_get_bring_jolla_weather")
        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        font.pixelSize: Theme.fontSizeExtraSmall
        wrapMode: Text.Wrap
        anchors {
            top: primaryLabel.bottom
            left: primaryLabel.left
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
    }
    Component {
        id: contextMenuComponent
        ContextMenu {
            property bool removeWhenClosed
            property bool menuOpen: height > 0

            onMenuOpenChanged: {
                if (!menuOpen && removeWhenClosed) {
                    removeComponent.createObject(root)
                    advertiseWeather = false
                }
            }
            MenuItem {
                //% "No thanks"
                text: qsTrId("lipstick-jolla-home-me-weather_no_thanks")
                onClicked: removeWhenClosed = true
            }
        }
    }
    Component {
        id: removeComponent
        SequentialAnimation {
            running: true
            NumberAnimation { target: root; properties: "opacity, height"; to: 0; duration: 400; easing.type: Easing.InOutQuad }
            ScriptAction { script: root.close() }
        }
    }
    DBusInterface {
        id: storeClientInterface
        service: "com.jolla.jollastore"
        path: "/StoreClient"
        iface: "com.jolla.jollastore"
    }
}
