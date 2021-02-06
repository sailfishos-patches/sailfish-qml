/*
 * Copyright (c) 2013 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.AccessControl 1.0
import com.jolla.messages.settings.translations 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.notifications 1.0
import org.nemomobile.ofono 1.0
import MeeGo.QOfono 0.2
import MeeGo.Connman 0.2

Column {
    id: simCardMessagingSettings
    width: parent.width

    property string modemPath
    property string imsi

    function updateSmsc() {
        if (smsc.text != ofonoMessageManager.serviceCenterAddress) {
            smscUpdater.createObject(pageStack, { "modemPath": modemPath, "newSmsc": smsc.text })
        }
    }

    SectionHeader {
        //: SMS settings section header
        //% "SMS"
        text: qsTrId("settings_messages-he-sms")
    }

    TextField {
        id: smsc
        width: parent.width
        //% "SMS Center address"
        label: qsTrId("settings_messages-la-smsc")
        placeholderText: label
        text: ofonoMessageManager.serviceCenterAddress
        inputMethodHints: Qt.ImhDialableCharactersOnly
        visible: AccessControl.hasGroup(AccessControl.RealUid, "sailfish-system")
        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: focus = false
        onActiveFocusChanged: {
            if (!activeFocus) {
                updateSmsc()
            }
        }
    }

    TextSwitch {
        id: deliveryReportsSwitch
        //% "Delivery reports"
        text: qsTrId("settings_messages-la-delivery_reports")
        //% "Request report when recipient receives the SMS"
        description: qsTrId("settings_messages-ls-delivery_reports_description")
        checked: ofonoMessageManager.useDeliveryReports
        visible: AccessControl.hasGroup(AccessControl.RealUid, "sailfish-system")
        onCheckedChanged: {
            busy = true
            reportsFailedMessage.visible = false
            ofonoMessageManager.useDeliveryReports = checked
        }
    }
    Label {
        id: reportsFailedMessage
        x: Theme.paddingLarge
        width: parent.width - 2*Theme.paddingLarge
        wrapMode: Text.Wrap
        visible: false
        //% "Changing delivery reports status failed"
        text: qsTrId("settings_messages-la-change_delivery_reports_failed")
    }

    TextSwitch {
        id: smsCharacterCountSwitch
        //% "Show character counter"
        text: qsTrId("settings_messages-la-show_character_counter")
        //% "Show the number of messages typed and the number of available characters remaining in the last message"
        description: qsTrId("settings_messages-ls-show_character_counter_description")
        checked: characterCountSetting.value
        automaticCheck: false
        onClicked: characterCountSetting.value = !checked

        ConfigurationValue {
            id: characterCountSetting
            key: "/apps/jolla-messages/show_sms_character_count"
            defaultValue: false
        }
    }

    SectionHeader {
        //: MMS settings section header
        //% "MMS"
        text: qsTrId("settings_messages-he-mms")
    }

    ComboBox {
        id: mmsMessageSizeSelection
        //: Selection of MMS maximum message size
        //% "Maximum message size"
        label: qsTrId("settings_messages-bt-mms_size")
        //% "Note that your or recipient's network service provider might restrict the message size"
        description: qsTrId("settings_messages-ls-mms_size_description")
        enabled: imsi !== ""
        value: (enabled && currentItem && currentItem.valueText !== "") ? currentItem.valueText : ""
        menu: mmsMessageSizeMenu
        ContextMenu {
            id: mmsMessageSizeMenu
            readonly property int defaultIndex: 1
            MenuItem {
                //: MMS maximum message size ComboBox item
                //% "Small (%1 kB)"
                text: qsTrId("settings_messages-me-mms_size_small").arg(sizeInBytes/1024)
                //: MMS maximum message size value
                //% "Small"
                property string valueText: qsTrId("settings_messages-la-mms_size_small")
                readonly property int sizeInBytes: 100*1024
            }
            MenuItem {
                //: MMS maximum message size ComboBox item
                //% "Medium (%1 kB)"
                text: qsTrId("settings_messages-me-mms_size_medium").arg(sizeInBytes/1024)
                //: MMS maximum message size value
                //% "Medium"
                property string valueText: qsTrId("settings_messages-la-mms_size_medium")
                readonly property int sizeInBytes: 300*1024
            }
            MenuItem {
                //: MMS maximum message size ComboBox item
                //% "Large (%1 kB)"
                text: qsTrId("settings_messages-me-mms_size_large").arg(sizeInBytes/1024)
                //: MMS maximum message size value
                //% "Large"
                property string valueText: qsTrId("settings_messages-la-mms_size_large")
                readonly property int sizeInBytes: 600*1024
            }
            MenuItem {
                //: MMS maximum message size ComboBox item
                //% "Extra large (%1 MB)"
                text: qsTrId("settings_messages-me-mms_size_extra_large").arg(sizeInBytes/1024/1024)
                //: MMS maximum message size value
                //% "Extra large"
                property string valueText: qsTrId("settings_messages-la-mms_size_extra_large")
                readonly property int sizeInBytes: 1*1024*1024
            }
        }
        onCurrentIndexChanged: if (currentItem) mmsMessageSize.value = currentItem.sizeInBytes
        Component.onCompleted: updateSelection(mmsMessageSize.value)
        function updateSelection(value) {
            if (value === undefined) {
                currentIndex = mmsMessageSizeMenu.defaultIndex
            } else {
                var n = mmsMessageSizeMenu.children.length
                for (var i=0; i<n; i++) {
                    if (value == mmsMessageSizeMenu.children[i].sizeInBytes) {
                        currentIndex = i
                        return
                    }
                }
                currentItem = null // Non-standard value
            }
        }
        ConfigurationValue {
            id: mmsMessageSize
            key: (imsi !== "") ? ("/imsi/" + imsi + "/mms/max-message-size") : ""
            onValueChanged: mmsMessageSizeSelection.updateSelection(value)
            defaultValue: mmsMessageSizeMenu.children[mmsMessageSizeMenu.defaultIndex].sizeInBytes
        }
    }

    ComboBox {
        id: mmsRequestReportsSelection
        //: Request MMS reports
        //% "Request reports"
        label: qsTrId("settings_messages-bt-mms_request_reports")
        //% "You can request report when recipient receives and/or reads the MMS"
        description: qsTrId("settings_messages-ls-mms_request_reports_description")
        enabled: imsi !== ""
        value: (enabled && currentItem && currentItem.text !== "") ? currentItem.text : ""
        menu: ContextMenu {
            //: Request MMS reports ComboBox item
            //% "None"
            MenuItem { text: qsTrId("settings_messages-me-mms_request_reports_none") }
            //: Request MMS reports ComboBox item
            //% "Delivery"
            MenuItem { text: qsTrId("settings_messages-me-mms_request_reports_delivery") }
            //: Request MMS reports ComboBox item
            //% "Read"
            MenuItem { text: qsTrId("settings_messages-me-mms_request_reports_read") }
            //: Request MMS reports ComboBox item
            //% "Both"
            MenuItem { text: qsTrId("settings_messages-me-mms_request_reports_both") }
        }
        // mmsSendMessageFlags is actually a bitmask:
        // 0x01  Request delivery report
        // 0x02  Request read report
        // but it conveniently matches the order of entries in the combo box
        onCurrentIndexChanged: mmsSendMessageFlags.value = currentIndex
        Component.onCompleted: currentIndex = mmsSendMessageFlags.value & 3
        ConfigurationValue {
            id: mmsSendMessageFlags
            key: (imsi !== "") ? ("/imsi/" + imsi + "/mms/send-flags") : ""
            onValueChanged: mmsRequestReportsSelection.currentIndex = value & 3
            defaultValue: 0
        }
    }

    TextSwitch {
        id: sendReadReportsSwitch
        //% "Send read reports"
        text: qsTrId("settings_messages-bt-mms_send_read_reports")
        //% "Sender gets information that you've opened the MMS"
        description: qsTrId("settings_messages-ls-mms_send_read_reports_description")
        enabled: imsi !== ""
        checked: enabled && sendReadReports.value
        automaticCheck: false
        onClicked: sendReadReports.value = !checked

        ConfigurationValue {
            id: sendReadReports
            key: (imsi !== "") ? ("/imsi/" + imsi + "/mms/send-read-reports") : ""
            defaultValue: false
        }
    }

    TextSwitch {
        id: mmsAutomaticDownloadSwitch
        //% "Download MMS automatically"
        text: qsTrId("settings_messages-bt-mms_auto_download")
        //% "Downloading MMS uses mobile data and might have additional costs"
        description: qsTrId("settings_messages-ls-mms_auto_download_description")
        enabled: imsi !== ""
        checked: enabled && mmsAutomaticDownload.value
        automaticCheck: false
        onClicked: mmsAutomaticDownload.value = !checked

        ConfigurationValue {
            id: mmsAutomaticDownload
            key: (imsi !== "") ? ("/imsi/" + imsi + "/mms/automatic-download") : ""
            defaultValue: true
        }
    }

    OfonoMessageManager {
        id: ofonoMessageManager
        modemPath: simCardMessagingSettings.modemPath
        onServiceCenterAddressChanged: smsc.text = serviceCenterAddress
        onUseDeliveryReportsChanged: deliveryReportsSwitch.checked = useDeliveryReports
        onSetUseDeliveryReportsComplete: {
            deliveryReportsSwitch.busy = false
            if (!success) {
                reportsFailedMessage.visible = true
                deliveryReportsSwitch.checked = useDeliveryReports
            }
        }
    }

    Component {
        id: smscUpdater
        OfonoMessageManager {
            property string newSmsc
            property var notification: Notification {
                isTransient: true
                urgency: Notification.Normal
            }
            onSetServiceCenterAddressComplete: {
                if (!success) {
                    //% "Changing the SMS Center address failed"
                    notification.body = qsTrId("settings_messages-la-change_smsc_failed")
                    notification.publish()
                }
                destroy()
            }
            Component.onCompleted: serviceCenterAddress = newSmsc
        }
    }
}
