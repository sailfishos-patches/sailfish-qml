import QtQuick 2.0
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
    property alias serverAddress: serverAddressField.text
    property alias addressbookPath: addressbookPathField.text
    property alias calendarPath: calendarPathField.text
    property alias webdavPath: webdavPathField.text
    property bool showAdvancedSettings

    property var servicesEnabledConfig: ({})

    function _serviceEnabledChanged(service, enable) {
        servicesEnabledConfig[service.name] = enable

        if (service.serviceType === "carddav") {
            addressbookPathField.visible = enable
        } else if (service.serviceType === "caldav") {
            calendarPathField.visible = enable
        }
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
                width: parent.width
                visible: root.showAdvancedSettings
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                placeholderText: label
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

            SectionHeader {
                //: Section header under which the user can toggle select various services to enable/disable
                //% "Services"
                text: qsTrId("settings_accounts-la-onlinesync_services")
            }

            Repeater {
                model: root.services

                delegate: TextSwitch {
                    text: AccountsUtil.serviceDisplayNameForService(modelData)
                    checked: true   // enable services by default

                    Component.onCompleted: root._serviceEnabledChanged(modelData, checked)
                    onCheckedChanged: root._serviceEnabledChanged(modelData, checked)
                }
            }

            Column {
                width: parent.width
                visible: root.showAdvancedSettings

                SectionHeader {
                    //% "Advanced settings"
                    text: qsTrId("components_accounts-la-advanced_settings")
                    visible: webdavPathField.visible
                             || addressbookPathField.visible
                             || calendarPathField.visible
                }

                TextField {
                    id: webdavPathField
                    width: parent.width
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    placeholderText: label
                    visible: text.length > 0
                    //: The field where the user can enter their WebDAV path
                    //% "WebDAV path"
                    label: qsTrId("components_accounts-la-webdav_path")

                    EnterKey.enabled: text || inputMethodComposing
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: addressbookPathField.focus = true
                }

                TextField {
                    id: addressbookPathField
                    width: parent.width
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    placeholderText: label
                    //: The field where the user can enter their addressbook home set path.  It is optional and can normally be automatically discovered.
                    //% "Address book path (optional)"
                    label: qsTrId("components_accounts-la-optional_addressbook_path")

                    EnterKey.enabled: text || inputMethodComposing
                    EnterKey.iconSource: "image://theme/icon-m-enter-next"
                    EnterKey.onClicked: calendarPathField.focus = true
                }

                TextField {
                    id: calendarPathField
                    width: parent.width
                    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    placeholderText: label
                    //: The field where the user can enter their calendar home set path.  It is optional and can normally be automatically discovered.
                    //% "Calendar path (optional)"
                    label: qsTrId("components_accounts-la-optional_calendar_path")

                    EnterKey.enabled: text || inputMethodComposing
                    EnterKey.iconSource: "image://theme/icon-m-enter-close"
                    EnterKey.onClicked: parent.focus = true
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
