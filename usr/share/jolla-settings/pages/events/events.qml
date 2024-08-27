import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import Nemo.Configuration 1.0

Page {
    id: page

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content

            width: parent.width

            PageHeader {
                //% "Events view"
                title: qsTrId("settings_events-he-events")
            }

            SectionHeader {
                //% "Widgets"
                text: qsTrId("settings_events-he-widgets")
                visible: lipstickSettings.lock_screen_events_allowed
            }

            Item {
                width: 1
                height: Theme.itemSizeMedium
                visible: eventsWidgetsModel.count == 0 && !lipstickSettings.lock_screen_events_allowed
            }

            InfoLabel {
                font.pixelSize: Theme.fontSizeLarge
                visible: eventsWidgetsModel.count == 0
                //: Placeholder label which is shown when there are no widgets which can be installed
                //% "No events view widgets are available for your device"
                text: qsTrId("settings_events-la-no_widgets_available")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                //: List of Events widgets that can be installed from store. %1 is replaced with
                //: a localised concatenation of widget names e.g: "Weather and Calendar".
                //% "Install %1 from Store."
                text: qsTrId("settings_events-la-install_from_store").arg(unavailableWidgets.value)
                visible: unavailableWidgets.value.length > 0
                wrapMode: Text.Wrap
                color: Theme.highlightColor
            }

            Repeater {
                model: eventsWidgetsModel
                TextSwitch {
                    text: model.title
                    description: model.description
                    automaticCheck: false
                    checked: model.enabled
                    enabled: model.available
                    onClicked: {
                        if (model.enabled)
                            eventsWidgetsModel.disableWidget(model.path)
                        else
                            eventsWidgetsModel.enableWidget(model.path)
                    }
                }
            }


            SectionHeader {
                //% "Beta"
                text: qsTrId("settings_events-he-beta")
            }

            TextSwitch {
                id: lockScreenEventsSwitch
                automaticCheck: false
                checked: lipstickSettings.lock_screen_events
                visible: lipstickSettings.lock_screen_events_allowed
                //% "Access Events when device is locked"
                text: qsTrId("settings_events-la-access_events_when_device_locked")
                onClicked: lipstickSettings.lock_screen_events = !lipstickSettings.lock_screen_events

                //% "When enabled you can check upcoming events and notifications "
                //% "from Lock Screen without unlocking the device"
                description: qsTrId("settings_events-la-access_events_when_device_locked_description")

                ConfigurationGroup {
                    id: lipstickSettings

                    path: "/desktop/lipstick-jolla-home"

                    property bool lock_screen_events: false
                    property bool lock_screen_events_allowed: true
                }
            }
        }

        VerticalScrollDecorator {}
    }

    EventsWidgetsModel {
        id: eventsWidgetsModel
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active)
                eventsWidgetsModel.updateAvailable()
        }
    }

    TitlesView {
        id: unavailableWidgets

        model: eventsWidgetsModel

        matchRole: "available"
        match: false
        role: "title"
    }
}
