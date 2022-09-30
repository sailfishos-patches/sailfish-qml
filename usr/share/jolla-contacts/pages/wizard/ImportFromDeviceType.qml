import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Page {
    id: root

    property string deviceType

    property var importFromFile
    property var createAccount
    property var abandonImport

    SilicaFlickable {
        id: flickable
        width: parent.width
        height: parent.height
        contentWidth: width
        contentHeight: actionColumn.y + actionColumn.height + Theme.paddingMedium

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: {
                    if (deviceType == 'android') {
                        //% "Android"
                        return qsTrId('contacts-he-header_import_from_android')
                    } else if (deviceType == 'iphone') {
                        //% "iPhone"
                        return qsTrId('contacts-he-header_import_from_iphone')
                    }
                    return ''
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - x - Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                textFormat: Text.AutoText
                color: Theme.highlightColor
                font { pixelSize: Theme.fontSizeMedium }

                text: {
                    if (deviceType == 'android') {
                        //% "Your contacts are probably automatically synchronized to your Google account. You can check this easily on your Android phone by going to 'Settings / Accounts / Google'.<br>"
                        //% "<br>"
                        //% "If the 'Sync contacts' option is selected, your contacts are available from your Google account and you can add this account to your device in 'Settings / Accounts' to sync your contacts.<br>"
                        //% "<br>"
                        //% "If 'Sync contacts' is not selected, you can select it then start a sync on your Android, then add your Google account to your device.<br>"
                        return qsTrId('contacts-la-prompt_import_from_android')
                    } else if (deviceType == 'iphone') {
                        //% "iPhones typically have contacts synced with iCloud. Quick steps:<br>"
                        //% "<br>"
                        //% "1. Log onto icloud.com<br>"
                        //% "2. Choose contacts<br>"
                        //% "3. Actions Menu > Select all<br>"
                        //% "4. Actions Menu > Export vCard<br>"
                        //% "<br>"
                        //% "Then transfer the vCard file to your device via Bluetooth or memory card."
                        return qsTrId('contacts-la-prompt_import_from_iphone')
                    }
                    return ''
                }
            }
            LinkButton {
                visible: deviceType == 'android'

                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin

                link: helpArticles.setup_google_account_link
                      ? helpArticles.setup_google_account_link
                      : 'https://jolla.zendesk.com/hc/en-us/articles/203726746'

                // Provide instructions for adding google account
                //% "Adding a Google account to your device"
                text: qsTrId("contacts-bt-add_google_account")
            }
            Label {
                visible: deviceType == 'android'

                x: Theme.horizontalPageMargin
                width: parent.width - x - Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font { pixelSize: Theme.fontSizeMedium }

                //: Prompt the user to import from Android without synchronization
                //% "If your contacts are not synchronized to a Google account and you don't want to use synchronization, you can create a contacts file (.vcf) and transfer that to your device."
                text: qsTrId("contacts-la-prompt_import_android_nonsync")
            }
            LinkButton {
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin

                link: {
                    if (deviceType == 'android') {
                        return helpArticles.import_android_link
                               ? helpArticles.import_android_link
                               : 'https://jolla.zendesk.com/hc/en-us/articles/201440847'
                    } else if (deviceType == 'iphone') {
                        return helpArticles.import_iphone_link
                               ? helpArticles.import_iphone_link
                               : 'https://jolla.zendesk.com/hc/en-us/articles/201440817'
                    }
                    return ''
                }

                // Link to detailed instructions on Jolla website
                //% "Learn More"
                text: qsTrId("contacts-bt-import_learn_more")
            }
        }

        ButtonLayout {
            id: actionColumn

            // Position buttons at the bottom of the page
            y: Math.max(flickable.height - (height + Theme.itemSizeMedium), contentColumn.y + contentColumn.height + Theme.paddingLarge)
            preferredWidth: Theme.buttonWidthMedium

            Button {
                //: Add google account
                //% "Sign in to Google account"
                text: qsTrId("contacts-bt-sign_in_goole")

                onClicked: createAccount('google')

                visible: deviceType == 'android'
            }
            Button {
                ButtonLayout.newLine: true

                //: Import from file
                //% "Import from file"
                text: qsTrId("contacts-bt-import_from_file")

                onClicked: importFromFile()

                visible: deviceType == 'android' || deviceType == 'iphone'
            }
            Button {
                ButtonLayout.newLine: true

                //: Cancel import procedure
                //% "Skip importing"
                text: qsTrId("contacts-bt-skip_importing")

                onClicked: abandonImport()
            }
        }

        VerticalScrollDecorator {}
    }

    ConfigurationGroup {
        id: helpArticles

        path: "/desktop/help-articles"

        property string import_android_link
        property string import_iphone_link
        property string setup_google_account_link
    }
}
