import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.dbus 2.0
import com.jolla.apkd 1.0

Page {
    id: root

    property string applicationName
    property string packageName
    property string packageVersion
    property string appSize
    property string dataSize
    property string cacheSize
    property string totalSize
    

    property bool autoStartReady: true
    property bool appSizeReady
    property bool error
    property bool autoStartAllowed: true
    property Item remorse

    DBusInterface {
        id: apkConfiguration

        bus: DBus.SystemBus
        service: "com.jolla.apkd"
        path: "/com/jolla/apkd"
        iface: "com.jolla.apkd"
        signalsEnabled: true

        function appStartOnBootupChanged(packageName, allowed) {
            if (packageName === root.packageName) {
                root.autoStartAllowed = allowed
            }
        }
    }

    BusyLabel {
        running: !(root.appSizeReady && root.autoStartReady) && !root.error
    }

    Label {
        visible: root.error
        width: parent.width - 2*Theme.horizontalPageMargin
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeExtraLarge
        color: Theme.highlightColor
        //% "Error getting application state"
        text: qsTrId("apkd_settings-la-error_getting_application_state")
    }

    function refreshSizes() {
        apkConfiguration.typedCall("getAppSize", [{"type": "s", "value": packageName}],
            function(sizeInfo) {
                appSize = Format.formatFileSize(sizeInfo[0])
                dataSize = Format.formatFileSize(sizeInfo[1])
                cacheSize = Format.formatFileSize(sizeInfo[2])
                totalSize = Format.formatFileSize(sizeInfo[0]+sizeInfo[1]+sizeInfo[2])
                root.appSizeReady = true
            },
            function() {
                root.error = true
            }
        )
    }

    Component.onCompleted: {
        apkConfiguration.typedCall("getAppStartOnBootup", [{"type": "s", "value": packageName}],
                                   function(isAllowed) {
                                       root.autoStartReady = true
                                       root.autoStartAllowed = isAllowed
                                   },
                                   function() {
                                       root.error = true
                                   })
         refreshSizes()
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: header.height + content.height + Theme.paddingLarge
        width: parent.width

        PageHeader {
            id: header
            title: applicationName
            //% "Version %1"
            description: root.packageVersion != "" ? qsTrId("apkd_settings-la-app_version").arg(root.packageVersion)
                                                   : ""
        }

        Column {
            id: content

            anchors.top: header.bottom
            enabled: root.appSizeReady && root.autoStartReady
            opacity: enabled ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {} }
            width: parent.width

            TextSwitch {
                //% "Allow application background services to start on bootup"
                text: qsTrId("apkd_settings-la-allow_background_service_start")
                //% "When this is off, you won't get app notifications"
                description: qsTrId("apkd_settings-la-allow_background_service_start_description")
                checked: root.autoStartAllowed
                automaticCheck: false
                onClicked: {
                    apkConfiguration.typedCall("setAppStartOnBootup", [{"type": "s", "value": packageName},
                                               {"type": "b", "value": !root.autoStartAllowed}])
                }
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            SectionHeader {
                //% "Storage"
                text: qsTrId("apkd_settings-la-package_storage")
            }

            //% "Total:"
            DetailItem { label: qsTrId("apkd_settings-la-appsize_total"); value: totalSize }
            //% "App:"
            DetailItem { label: qsTrId("apkd_settings-la-appsize_app"); value: appSize }
            DetailItem {
                //% "Data:"
                label: qsTrId("apkd_settings-la-appsize_data")
                value: root.remorse && root.remorse.active ? Format.formatFileSize(0)
                                                           : dataSize
            }
            //% "Cache:"
            DetailItem { label: qsTrId("apkd_settings-la-appsize_cache"); value: cacheSize }

            SectionHeader {
                //% "Actions"
                text: qsTrId("apkd_settings-la-package_actions")
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: implicitHeight + Theme.paddingMedium
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                //% "Open the Android™ Settings page for this app. "
                //% "Adjust permissions, notification settings from within Android™."
                text: qsTrId("apkd_settings-la-open-alien-settings-description")
            }
            Item {
                width: 1
                height: Theme.paddingMedium
            }
            Button {
                preferredWidth: Theme.buttonWidthMedium
                anchors.horizontalCenter: parent.horizontalCenter
                //% "Open Android™ Settings"
                text: qsTrId("apkd_settings-open-alien-settings")
                onClicked: {
                    apkConfiguration.call("openAppSettings", [root.packageName])
                    
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: implicitHeight + Theme.paddingMedium
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                //% "This clears the temporary cache used by the app. It does not affect your data."
                //% "The app might take longer to start after clearing the cache."
                text: qsTrId("apkd_settings-la-package_clear_cache_description")
            }
            Item {
                width: 1
                height: Theme.paddingMedium
            }
            Button {
                preferredWidth: Theme.buttonWidthMedium
                anchors.horizontalCenter: parent.horizontalCenter
                //% "Clear cache"
                text: qsTrId("apkd_settings-la-package_clear_cache")
                onClicked: {
                    root.appSizeReady = false;
                    apkConfiguration.call("deleteAppCacheFiles", [root.packageName], function() { refreshSizes() })
                    
                }
            }


            Item {
                width: 1
                height: Theme.paddingLarge
            }


            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: implicitHeight + Theme.paddingMedium
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                //% "This reverts the app to a clean state as if it was just installed. You will lose all your data in the app "
                //% "(e.g. saved preferences, game scores)."
                text: qsTrId("apkd_settings-la-clear_data_description")
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            Button {
                preferredWidth: Theme.buttonWidthMedium
                anchors.horizontalCenter: parent.horizontalCenter
                //% "Clear data"
                text: qsTrId("apkd_settings-la-package_clear_data")
                onClicked: { 
                    //% "Cleared app data"
                    root.remorse = Remorse.popupAction(root, qsTrId("apkd_settings-la-package_cleared_data"), function() {
                        root.appSizeReady = false
                        apkConfiguration.call("clearAppUserData", [root.packageName], function() { refreshSizes() })
                    })
                }
            }


            Item {
                width: 1
                height: Theme.paddingLarge
            }


            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                height: implicitHeight + Theme.paddingMedium
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                //% "Force stopping an app will also stop notifications. The app might restart automatically via background processes."
                text: qsTrId("apkd_settings-la-package_stop_description")
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            Button {
                preferredWidth: Theme.buttonWidthMedium
                anchors.horizontalCenter: parent.horizontalCenter
                //% "Force stop"
                text: qsTrId("apkd_settings-la-package_stop")
                onClicked: {
                    apkConfiguration.call("forceStopApp", [root.packageName])
                }
            }
        }
    }
}
