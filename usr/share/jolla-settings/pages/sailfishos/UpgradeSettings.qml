/****************************************************************************
**
** Copyright (c) 2013-2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
** License: Proprietary
**
****************************************************************************/
import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import Nemo.Configuration 1.0
import com.jolla.settings.sailfishos 1.0
import org.nemomobile.ofono 1.0

Item {
    property int horizontalMargin: Theme.horizontalPageMargin
    property bool haveCellular: modemManager.availableModems.length > 0

    width: parent.width
    height: settingsColumn.height

    OfonoModemManager {
        id: modemManager
    }

    ConfigurationValue {
       id: checkMethodConfig
       key: "/apps/store-client/settings/os_update_check_method"
       defaultValue: 1
    }

    /*
    ConfigurationValue {
       id: downloadMethodConfig
       key: "/apps/store-client/settings/os_update_download_method"
       defaultValue: 0
    }
    */

    Column {
        id: settingsColumn
        width: parent.width
        visible: storeIf.accountStatus === StoreInterface.AccountAvailable

        SectionHeader {
            //: Section header text for OS update settings
            //% "OS update settings"
            text: qsTrId("settings_sailfishos-la-os_update_settings")
        }

        ComboBox {
            id: checkMethodCombo

            enabled: AccessPolicy.osUpdatesEnabled
            leftMargin: horizontalMargin
            rightMargin: horizontalMargin
            //: Combo box label for the "check for updates" setting
            //% "Check for updates"
            label: qsTrId("settings_sailfishos-la-check_method")
            currentIndex: checkMethodConfig.value
            menu: ContextMenu {
                MenuItem {
                    //: Settings option for "check for updates" and "download updates" combo boxes.
                    //% "Manual"
                    text: qsTrId("settings_sailfishos-me-manual")
                }
                MenuItem {
                    text: haveCellular
                          //: Settings option for "check for updates" and "download updates" combo boxes.
                          //% "WLAN only"
                          ? qsTrId("settings_sailfishos-me-wlan_only")
                          //: Settings option for "check for updates" and "download updates" combo boxes.
                          //% "Automatic"
                          : qsTrId("settings_sailfishos-me-automatic")
                }
                MenuItem {
                    //: Settings option for "check for updates" and "download updates" combo boxes.
                    //% "Always"
                    text: qsTrId("settings_sailfishos-me-always")
                    visible: haveCellular
                }
            }

            onCurrentIndexChanged: checkMethodConfig.value = currentIndex
        }

        /*
        ComboBox {
            id: downloadMethodCombo

            leftMargin: horizontalMargin
            rightMargin: horizontalMargin
            //: Combo box label for the "download updates" setting
            //% "Download updates"
            label: qsTrId("settings_sailfishos-la-download_method")
            currentIndex: downloadMethodConfig.value
            menu: ContextMenu {
                MenuItem {
                    text: qsTrId("settings_sailfishos-me-manual")
                }
                MenuItem {
                    text: haveCellular
                          ? qsTrId("settings_sailfishos-me-wlan_only")
                          : qsTrId("settings_sailfishos-me-automatic")
                }
                MenuItem {
                    text: qsTrId("settings_sailfishos-me-always")
                    visible: haveCellular
                }
            }

            onCurrentIndexChanged: downloadMethodConfig.value = currentIndex
        }
    */
    }
}
