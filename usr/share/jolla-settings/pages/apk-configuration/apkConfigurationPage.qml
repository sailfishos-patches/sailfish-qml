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
    

    property bool autoStartReady
    property bool appSizeReady
    property bool error
    property bool autoStartAllowed

    DBusInterface {
        id: apkConfiguration

        bus: DBus.SystemBus
        service: "com.myriadgroup.alien.settings"
        path: "/com/myriadgroup/alien/settings"
        iface: "com.myriadgroup.alien.settings"
        signalsEnabled: true

        function appStartOnBootupChanged(packageName, allowed) {
            if (packageName === root.packageName) {
                root.autoStartAllowed = allowed
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: !(root.appSizeReady && root.autoStartReady) && !root.error
        size: BusyIndicatorSize.Large
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
            visible: root.appSizeReady && root.autoStartReady
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
            //% "Data:"
            DetailItem { label: qsTrId("apkd_settings-la-appsize_data"); value: dataSize }
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
                	//% "Clearing app data"
                    dataRemorse.execute(qsTrId("apkd_settings-la-package_clearing_data"), function() {
                        root.appSizeReady = false
                        apkConfiguration.call("clearAppUserData", [root.packageName], function() { refreshSizes() })
                    })  
                }

                RemorsePopup { id: dataRemorse }
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
