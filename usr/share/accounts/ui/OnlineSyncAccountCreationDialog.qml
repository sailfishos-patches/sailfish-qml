/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

Dialog {
    id: root

    property Provider accountProvider
    property var services: []

    property string usernameLabel
    property alias username: usernameField.text
    property alias password: passwordField.text
    property alias extraText: extraTextLabel.text
    property alias serverAddress: serverAddressField.text
    property alias addressbookPath: advancedSettings.addressbookPath
    property alias calendarPath: advancedSettings.calendarPath
    property alias webdavPath: advancedSettings.webdavPath
    property alias imagesPath: advancedSettings.imagesPath
    property alias backupsPath: advancedSettings.backupsPath
    property bool showAdvancedSettings
    property alias ignoreSslErrors: ignoreSslErrorsSwitch.checked

    property var servicesEnabledConfig: ({})

    function _serviceEnabledChanged(service, enable) {
        servicesEnabledConfig[service.name] = enable
        advancedSettings.setServiceFieldEnabled(service, enable)
    }

    canAccept: username.length > 0 && password.length > 0

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: header.height + accountSummary.height + settingsColumn.height

        DialogHeader {
            id: header
            dialog: root.dialog
            acceptText: root.canSkip ? root.skipText : defaultAcceptText
        }

        Item {
            id: accountSummary
            anchors {
                top: header.bottom
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
            }
            height: icon.height + Theme.paddingLarge

            Image {
                id: icon
                anchors.top: parent.top
                width: Theme.iconSizeLarge
                height: width
                source: root.accountProvider ? root.accountProvider.iconName : ""
            }
            Label {
                anchors {
                    left: icon.right
                    leftMargin: Theme.paddingLarge
                    right: parent.right
                    verticalCenter: icon.verticalCenter
                }
                text: root.accountProvider.displayName
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeLarge
                truncationMode: TruncationMode.Fade
            }
        }

        Column {
            id: settingsColumn
            anchors {
                top: accountSummary.bottom
                left: parent.left
                right: parent.right
            }

            Label {
                id: extraTextLabel
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: Theme.horizontalPageMargin
                }
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
                height: extraTextLabel.text.length > 0 ? (implicitHeight + Theme.paddingLarge) : 0
            }

            AccountUsernameField {
                id: usernameField
                label: usernameLabel.length == 0 ? defaultLabel : usernameLabel
                EnterKey.onClicked: passwordField.focus = true
            }

            PasswordField {
                id: passwordField
                EnterKey.iconSource: serverAddressField.visible ? "image://theme/icon-m-enter-next" : "image://theme/icon-m-enter-close"
                EnterKey.onClicked: {
                    if (serverAddressField.visible) {
                        serverAddressField.focus = true
                    } else {
                        parent.focus = true
                    }
                }
            }

            TextField {
                id: serverAddressField

                visible: root.showAdvancedSettings
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

                //% "Server address"
                label: qsTrId("components_accounts-la-server_address")

                onActiveFocusChanged: {
                    if (!activeFocus
                            && text.length > 0
                            && text.search(/^\S+:/) < 0) { // check the url starts with a protocol
                        text = "https://" + serverAddress
                    }
                }

                EnterKey.enabled: text || inputMethodComposing
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: parent.focus = true
            }

            TextSwitch {
                id: ignoreSslErrorsSwitch
                //: Switch to ignore SSL security errors
                //% "Ignore SSL Errors"
                text: qsTrId("components_accounts-la-jabber_ignore_ssl_errors")
            }

            SectionHeader {
                //: Section header under which the user can toggle select various services to enable/disable
                //% "Services"
                text: qsTrId("settings_accounts-la-onlinesync_services")
            }

            Repeater {
                id: serviceRepeater

                model: root.services

                delegate: IconTextSwitch {
                    text: AccountsUtil.serviceDisplayNameForService(modelData)
                    icon.source: modelData.iconName
                    description: AccountsUtil.serviceDescription(modelData, accountProvider.displayName, accountProvider.name)

                    checked: true   // enable services by default
                    automaticCheck: false

                    Component.onCompleted: root._serviceEnabledChanged(modelData, checked)
                    onCheckedChanged: root._serviceEnabledChanged(modelData, checked)

                    onClicked: {
                        if (checked && AccountsUtil.countCheckedSwitches(serviceRepeater) === 1) {
                            minimumServiceEnabledNotification.publish()
                            return
                        }
                        checked = !checked
                    }
                }
            }

            SectionHeader {
                //% "Advanced settings"
                text: qsTrId("components_accounts-la-advanced_settings")
                visible: root.showAdvancedSettings
                opacity: advancedSettings.opacity
            }

            OnlineSyncAccountAdvancedSettings {
                id: advancedSettings

                visible: root.showAdvancedSettings

                // The default server paths may depend on the username and server address values,
                // so disable the path input fields until those two values have been entered.
                enabled: usernameField.text.length > 0
                        && serverAddressField.text.length > 0

                Component.onCompleted: {
                    // No account argument, as account is not yet created, so cannot load
                    // saved service settings.
                    load(null, root.services)
                }
            }
        }

        VerticalScrollDecorator {}
    }

    MinimumServiceEnabledNotification {
        id: minimumServiceEnabledNotification
    }
}
