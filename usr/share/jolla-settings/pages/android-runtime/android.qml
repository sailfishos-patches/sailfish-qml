import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.configuration 1.0
import com.jolla.apkd 1.0

Page {
    id: root

    property string alienDalvikState
    property bool alienDalvikAutostart

    DBusInterface {
        id: apkInterface

        bus: DBus.SystemBus
        service: "com.jolla.apkd"
        path: "/com/jolla/apkd"
        iface: "com.jolla.apkd"
    }

    DBusInterface {
        id: dalvikService

        bus: DBus.SystemBus
        service: "org.freedesktop.systemd1"
        iface: "org.freedesktop.systemd1.Unit"
        signalsEnabled: true

        function updateProperties() {
            if (path !== "") {
                root.alienDalvikState  = dalvikService.getProperty("ActiveState");
            } else {
                root.alienDalvikState = ""
            }
        }

        onPropertiesChanged: runningUpdateTimer.start()
        onPathChanged: updateProperties()
    }

    DBusInterface {
        id: manager

        bus: DBus.SystemBus
        service: "org.freedesktop.systemd1"
        path: "/org/freedesktop/systemd1"
        iface: "org.freedesktop.systemd1.Manager"
        signalsEnabled: true

        signal unitNew(string name)
        onUnitNew: {
            if (name == "aliendalvik.service") {
                pathUpdateTimer.start()
            }
        }

        signal unitRemoved(string name)
        onUnitRemoved: {
            if (name == "aliendalvik.service") {
                dalvikService.path = ""
                pathUpdateTimer.stop()
            }
        }

        signal unitFilesChanged()
        onUnitFilesChanged: {
            updateAutostart()
        }

        Component.onCompleted: {
            updatePath()
            updateAutostart()
        }

        function updateAutostart() {
            manager.typedCall("GetUnitFileState", [{"type": "s", "value": "aliendalvik.service"}],
                              function(state) {
                                  if (state !== "disabled" && state !== "invalid") {
                                      root.alienDalvikAutostart = true
                                  } else {
                                      root.alienDalvikAutostart = false
                                  }
                              },
                              function() {
                                  root.alienDalvikAutostart = false
                              })
        }

        function updatePath() {
            manager.typedCall("GetUnit", [{ "type": "s", "value": "aliendalvik.service"}], function(unit) {
                dalvikService.path = unit
            }, function() {
                dalvikService.path = ""
            })
        }
    }

    Timer {
        // starting and stopping can result in lots of property changes
        id: runningUpdateTimer
        interval: 100
        onTriggered: dalvikService.updateProperties()
    }

    Timer {
        // stopping service can result in unit appearing and disappering, for some reason.
        id: pathUpdateTimer
        interval: 100
        onTriggered: manager.updatePath()
    }

    ConfigurationValue {
        id: packageReplaceConfig
        key: "/alien/persist.package.replacement.enabled"
        defaultValue: false
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height + Theme.paddingMedium
        width: parent.width

        Column {
            id: content

            width: parent.width

            PageHeader {
                id: header
                //% "Android™ App Support"
                title: qsTrId("android_settings-header")
            }

            TextSwitch {
                id: autostart

                //% "Start Android App Support on bootup"
                text: qsTrId("android_settings-la-autostart")
                //% "When this is off, you won't get any Android app notifications and launching first Android app"
                //% " can take a lot of time"
                description: qsTrId("android_settings-la-autostart_description")
                automaticCheck: false
                checked: root.alienDalvikAutostart
                onClicked: {
                    apkInterface.typedCall("controlServiceAutostart", [{ "type": "b", "value": !checked }],
                                           undefined,
                                           function() { console.warn("Error changing Android autostart state")})
                }
            }

            SectionHeader {
                //% "Permissions"
                text: qsTrId("android_settings-la-permissions")
            }

            TextSwitch {
                //% "Disable Android App Support system package verification"
                text: qsTrId("android_settings-bt-allow_pkg_replace")
                //% "Allow substitution of system packages with unofficial versions. "
                //% "You must also grant this permission to each package individually within Android App Support. Changing this setting requires a restart of Android App Support. "
                //% "Caution: malicious apps may try to use this to access personal data. "
                description: qsTrId("android_settings-la-allow_pkg_replace_description")
                automaticCheck: false
                checked: packageReplaceConfig.value
                onClicked: {
                    packageReplaceConfig.value = !packageReplaceConfig.value
                }
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            SectionHeader {
                //% "Actions"
                text: qsTrId("android_settings-la-actions_header")
            }


            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*Theme.horizontalPageMargin
                //% "Starting Android App Support takes a while. Stopping Android App Support will also stop Android app "
                //% "notifications and other background processes."
                text: qsTrId("android_settings-la-android_start_stop_description")
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }
            ButtonLayout {
                Button {
                    // Enable start button if aliendalvik service state is inactive or if the state is unknown
                    // Service state is unknown if aliendalvik service is not enabled at boot and service is not running
                    enabled: root.alienDalvikState == "inactive" || root.alienDalvikState == "" || root.alienDalvikState === undefined
                    //% "Start"
                    text: qsTrId("android_settings-bt-start_android_support")
                    onClicked: apkInterface.typedCall("controlService", [{ "type": "b", "value": true }])
                }

                Button {
                    enabled: root.alienDalvikState == "active"
                    //% "Stop"
                    text: qsTrId("android_settings-bt-stop_android_support")
                    onClicked: apkInterface.typedCall("controlService", [{ "type": "b", "value": false }])
                }
            }
        }
    }
}
