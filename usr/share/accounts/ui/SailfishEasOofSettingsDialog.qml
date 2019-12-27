import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0
import org.nemomobile.notifications 1.0 as SystemNotifications
import com.jolla.sailfisheas 1.0

Dialog {
    id: root

    property OofSettings oofSettings
    property var account
    property bool error

    readonly property real switchAlignment: Theme.horizontalPageMargin - Theme.paddingLarge + Theme.itemSizeExtraSmall

    function _populateOofSettings() {
        var time = new Date()
        if (oofSettings.endTime > time) {
            timeRangeSelector.setStartDate(oofSettings.startTime)
            timeRangeSelector.setEndDate(oofSettings.endTime)
        } else {
            console.log("no valid time data, setting to current")
            // no valid data available, default to next starting hour + next day
            time.setHours(time.getHours() + 1, 0, 0)
            timeRangeSelector.setStartDate(time)
            time.setDate(time.getDate() + 1)
            timeRangeSelector.setEndDate(time)
        }

        externalAudience.currentIndex = oofSettings.externalMessageToAnyone ? 0 : 1
    }

    canAccept: (!timeRangeSelector.showError || !timeRangeSwitch.checked) && !root.error
               && oofSettings.state != OofSettings.Getting

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.y + (column.visible ? column.height : 0)

        VerticalScrollDecorator {}

        DialogHeader {
            id: header
            //% "Save"
            acceptText: qsTrId("settings-accounts-oof_save")
        }

        Column {
            id: column

            width: parent.width
            anchors.top: header.bottom
            opacity: oofSettings.state != OofSettings.Getting && !root.error ? 1.0 : 0.0
            bottomPadding: Theme.paddingMedium

            TextSwitch {
                id: oofSwitch

                checked: oofSettings.oofEnabled
                automaticCheck: false
                onClicked: oofSettings.oofEnabled = !oofSettings.oofEnabled

                //% "Send automatic replies"
                text: qsTrId("settings-accounts-la-oof_send")
            }

            Column {
                width: parent.width
                enabled: oofSwitch.checked

                TextSwitch {
                    id: timeRangeSwitch

                    enabled: parent.enabled
                    checked: oofSettings.timeRangeEnabled
                    automaticCheck: false
                    onClicked: oofSettings.timeRangeEnabled = !oofSettings.timeRangeEnabled
                    //% "Only send during a period"
                    text: qsTrId("settings-accounts-oof_send_time_range")
                }

                TimeRangeSelector {
                    id: timeRangeSelector

                    leftMargin: switchAlignment
                    visible: timeRangeSwitch.checked
                    // TODO: could also check that the whole range is not in the past
                    showError: startDate >= endDate
                    opacity: enabled ? 1.0 : 0.4
                }

                SectionHeader {
                    //% "Inside my organization"
                    text: qsTrId("settings_accounts-la-oof_section_internal")
                    opacity: enabled ? 1.0 : 0.4
                }

                TextArea {
                    id: internalMessageText
                    width: parent.width
                    placeholderText: label
                    //% "Message inside my organization"
                    label: qsTrId("settings-accounts-ph-message_for_internal_description")
                    text: oofSettings.internalMessage
                }

                SectionHeader {
                    //% "Outside my organization"
                    text: qsTrId("settings_accounts-la-oof_section_external")
                    opacity: enabled ? 1.0 : 0.4
                }

                TextSwitch {
                    id: replyExternalSwitch

                    enabled: parent.enabled
                    checked: oofSettings.externalMessageEnabled
                    automaticCheck: false
                    onClicked: oofSettings.externalMessageEnabled = !oofSettings.externalMessageEnabled
                    //% "Send outside my organisation"
                    text: qsTrId("settings-accounts-auto-reply_external")
                }

                ComboBox {
                    id: externalAudience

                    leftMargin: switchAlignment
                    enabled: replyExternalSwitch.checked && replyExternalSwitch.enabled
                    //% "Auto-reply to"
                    label: qsTrId("settings-accounts-auto-reply_to")
                    menu: ContextMenu {
                        MenuItem {
                            //% "Anyone"
                            text: qsTrId("settings-accounts-anyone")
                        }
                        MenuItem {
                            //% "Known contacts only"
                            text: qsTrId("settings-accounts-contacts_only")
                        }
                    }
                }

                TextArea {
                    id: externalMessageText

                    width: parent.width
                    placeholderText: label
                    //% "Message outside my organziation"
                    label: qsTrId("settings-accounts-ph-message_for_external_description")
                    text: oofSettings.externalMessage
                    enabled: replyExternalSwitch.checked
                }
            }
        }
    }

    Connections {
        target: oofSettings
        onRetrieveOofSettingsCompleted: {
            _populateOofSettings()
            root.error = !success
        }
    }

    Component.onCompleted: {
        oofSettings.retrieveOofSettings(account.identifier)
    }

    SystemNotifications.Notification {
        id: systemNotification

        icon: "icon-lock-calendar"
        isTransient: true
        //% "Auto-reply start time needs to be before end time"
        previewBody: qsTrId("jolla-oof-error-message-end_before_start")
    }

    onAcceptBlocked: {
        if (root.error || oofSettings.state == OofSettings.Getting || !timeRangeSwitch.checked) {
            return
        }

        if (timeRangeSelector.startDate >= timeRangeSelector.endDate) {
            systemNotification.publish()
        }
    }

    onAccepted: {
        // Sync settings that don't have direct two-way bindings
        oofSettings.startTime = timeRangeSelector.startDate
        oofSettings.endTime = timeRangeSelector.endDate
        oofSettings.externalMessageToAnyone = externalAudience.currentIndex == 0
        oofSettings.internalMessage = internalMessageText.text
        oofSettings.externalMessage = externalMessageText.text
        oofSettings.sendOofSettings(account.identifier)
    }

    onRejected: oofSettings.cancel()

    Item {
        anchors.fill: parent
        opacity: (oofSettings.state == OofSettings.Getting || root.error) ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity { FadeAnimator{} }

        BusyIndicator {
            anchors.bottom: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            running: !root.error
            size: BusyIndicatorSize.Large
        }

        HighlightImage {
            source: "image://theme/icon-l-attention"
            highlighted: true
            anchors.bottom: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.error
        }

        Label {
            width: parent.width - 2*x
            x: Theme.horizontalPageMargin
            anchors.top: parent.verticalCenter
            anchors.topMargin: Theme.paddingLarge
            color: Theme.highlightColor
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter

            text: root.error
                  ? //% "Error getting auto-reply settings from the server"
                    qsTrId("components_accounts-la-activesync-getting_oof_settings_failed")
                  : //% "Retrieving auto-reply settings from the server"
                    qsTrId("components_accounts-la-activesync-getting_oof_settings")
        }
    }
}
