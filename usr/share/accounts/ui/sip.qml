import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountCreationAgent {
    id: root

    property Item _settingsDialog

    initialPage: Dialog {
        canAccept: settings.acceptableInput
        acceptDestination: busyComponent

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: contentColumn.height + Theme.paddingLarge

            Column {
                id: contentColumn
                width: parent.width

                DialogHeader {
                    dialog: initialPage
                }

                Item {
                    x: Theme.horizontalPageMargin
                    width: parent.width - x*2
                    height: icon.height + Theme.paddingLarge

                    Image {
                        id: icon
                        width: Theme.iconSizeLarge
                        height: width
                        anchors.top: parent.top
                        source: root.accountProvider.iconName
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

                SIPCommon {
                    id: settings
                }
            }

            VerticalScrollDecorator {}
        }
    }

    Component {
        id: busyComponent
        AccountBusyPage {
            onStatusChanged: {
                if (status == PageStatus.Active) {
                    accountFactory.beginCreation()
                }
            }
        }
    }

    AccountFactory {
        id: accountFactory
        function beginCreation() {
            var configuration = {}

            for (var i = 0; i < settings.children.length; i++) {
                var item = settings.children[i]
                var value

                if (!item._tpType) continue

                if (item._tpType == 's')
                    value = item.text == item._tpDefault || item.text === '' ? null : item.text
                else if (item._tpType == 'b')
                    value = item.checked == item._tpDefault ? null : item.checked
                else if (item._tpType == 'e')
                    value = item.currentItem._tpValue == item._tpDefault ? null : item.currentItem._tpValue

                if (value !== null) {
                    var tpParam = 'telepathy/' + item._tpParam

                    console.log(tpParam + ' = ' + value)
                    configuration[tpParam] = value
                }
            }

            createAccount(root.accountProvider.name,
                root.accountProvider.serviceNames[0],
                settings.account, settings.password,
                settings.account,
                { "sip": configuration },       // configuration map
                "Jolla",  // applicationName
                "",       // symmetricKey
                "Jolla")  // credentialsName
        }

        onError: {
            console.log("SIP creation error:", message)
            initialPage.acceptDestinationInstance.state = "info"
            initialPage.acceptDestinationInstance.infoExtraDescription = message
            root.accountCreationError(message)
        }

        onSuccess: {
            root._settingsDialog = settingsComponent.createObject(root, {"accountId": newAccountId})
            pageStack.animatorPush(root._settingsDialog)
            root.accountCreated(newAccountId)
        }
    }

    Component {
        id: settingsComponent
        Dialog {
            property alias accountId: settingsDisplay.accountId

            acceptDestination: root.endDestination
            acceptDestinationAction: root.endDestinationAction
            acceptDestinationProperties: root.endDestinationProperties
            acceptDestinationReplaceTarget: root.endDestinationReplaceTarget
            backNavigation: false

            onAccepted: {
                root.delayDeletion = true
                settingsDisplay.saveAccount()
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

                DialogHeader {
                    id: header
                }

                SIPSettingsDisplay {
                    id: settingsDisplay
                    anchors.top: header.bottom
                    accountProvider: root.accountProvider
                    autoEnableAccount: true

                    onAccountSaveCompleted: {
                        root.delayDeletion = false
                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }
}
