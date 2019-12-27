/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
import Nemo.Email 0.1
import com.jolla.email.settings.translations 1.0

Page {
    EmailAccountListModel {
        id: mailAccountListModel
        onlyTransmitAccounts: true
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                //: Email settings page header
                //% "Mail"
                title: qsTrId("settings_email-he-email")
            }

            TextSwitch {
                //% "Download images automatically"
                text: qsTrId("settings_email-la-default_download_images")
                //: Description informing the user that downloading images automatically might subject his mailbox to spam
                //% "Automatically downloading images might subject your mailbox to spam."
                description: qsTrId("settings_email-la-default_download_images_description")
                checked: downloadImagesConfig.value

                onCheckedChanged: downloadImagesConfig.value = checked
            }

            Loader {
                // crypto.qml is installed by the crypto-gnupg subpackage.
                active: emailAppCryptoEnabled
                source: "crypto.qml"
                width: parent.width
            }

            ComboBox {
                id: readReceiptsPolicy
                //% "Send read receipts policy"
                label: qsTrId("settings_email-la-default_send_read_receipts")
                //: Description informing the user that email client will send read receipts automatically without any additional indications if it was requested by a sender
                //% "What should be done when read receipt requested?"
                description: qsTrId("settings_email-la-default_send_read_receipts_description")
                currentIndex: sendReadReceiptsConfig.value
                menu: ContextMenu {
                    MenuItem {
                        //% "Always ask"
                        text: qsTrId("settings_email-la-always_ask_read_receipt")
                    }
                    MenuItem {
                        //% "Always send"
                        text: qsTrId("settings_email-la-always_send_read_receipt")
                    }
                    MenuItem {
                        //% "Always ignore"
                        text: qsTrId("settings_email-la-always_ignore_read_receipt")
                    }
                }

                onCurrentIndexChanged: sendReadReceiptsConfig.value = currentIndex
            }

            ComboBox {
                visible: mailAccountListModel.numberOfAccounts > 1
                currentIndex: Math.max(0, mailAccountListModel.indexFromAccountId(defaultAccountConfig.value))
                //% "Default sending account"
                label: qsTrId("settings_email-la-default_sending_account")
                menu: ContextMenu {
                    Repeater {
                        model: mailAccountListModel
                        MenuItem {
                            text: displayName != "" ? displayName : emailAddress
                            onClicked: defaultAccountConfig.value = mailAccountId
                        }
                    }
                }
            }
        }
        VerticalScrollDecorator {}
    }

    ConfigurationValue {
        id: defaultAccountConfig
        key: "/apps/jolla-email/settings/default_account"
        defaultValue: mailAccountListModel.numberOfAccounts > 1 ? mailAccountListModel.accountId(0) : 0
    }

    ConfigurationValue {
        id: downloadImagesConfig
        key: "/apps/jolla-email/settings/downloadImages"
        defaultValue: false
    }
    ConfigurationValue {
        id: sendReadReceiptsConfig
        key: "/apps/jolla-email/settings/sendReadReceipts"
        defaultValue: 0
        onValueChanged: {
            readReceiptsPolicy.currentIndex = value
        }
    }
}
