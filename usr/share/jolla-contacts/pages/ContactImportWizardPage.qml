import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import Sailfish.Bluetooth 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.contacts 1.0
import com.jolla.settings.accounts 1.0
import com.jolla.signonuiservice 1.0

Dialog {
    id: root

    acceptDestination: importFromServices
    acceptDestinationAction: PageStackAction.Push

    function importFromFile() {
        var obj = pageStack.animatorPush("../ContactFilePickerPage.qml")
        obj.pageCompleted.connect(function(page) {
            page.onFileSelected.connect(function(fileUrl) {
                openImportPage({ "importSourceUrl": fileUrl }, true)
            })
        })
    }

    function bluetoothPairing(returnPage) {
        pageStack.animatorPush(bluetoothPairingDialogComponent,
                               { 'acceptDestination': returnPage, 'acceptDestinationAction': PageStackAction.Pop })
    }

    Component {
        id: bluetoothPairingDialogComponent

        BluetoothDevicePickerDialog {
            requirePairing: true
        }
    }

    function createAccount(providerName) {
        jolla_signon_ui_service.inProcessParent = root
        accountCreator.endDestination = pageStack.currentPage
        accountCreator.endDestinationAction = PageStackAction.Pop
        accountCreator.startAccountCreationForProvider(providerName, {}, PageStackAction.Push)
    }

    function abandonImport() {
        // Pop down to the contact list
        pageStack.pop(pageStack.previousPage(root))
    }

    function openImportPage(properties, replace) {
        var obj
        if (replace) {
            obj = pageStack.animatorReplace("ContactImportPage.qml", properties)
        } else {
            obj = pageStack.animatorPush("ContactImportPage.qml", properties)
        }
        obj.pageCompleted.connect(function(page) {
            page.contactOpenRequested.connect(function(contactId) {
                if (contactId != undefined) {
                    pageStack.animatorReplace("Sailfish.Contacts.ContactCardPage", {
                                                  "contact": peopleModel.personById(contactId)
                                              })
                } else {
                    // Pop down to the contact list
                    pageStack.pop(pageStack.previousPage(root))
                }
            })
        })
    }

    SilicaFlickable {
        width: parent.width
        height: parent.height
        contentWidth: width
        contentHeight: contentColumn.height + Theme.paddingMedium

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingLarge

            DialogHeader {
                id: header

                //: Import label to go to import options
                //% "Import"
                acceptText: qsTrId("contacts-he-import")
            }
            Column {
                width: parent.width
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - x - Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    font { pixelSize: Theme.fontSizeLarge }

                    //: Functional title
                    //% "Import Contacts"
                    text: qsTrId("contacts-la-import_contacts")
                }
                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - x - Theme.horizontalPageMargin
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    font { pixelSize: Theme.fontSizeMedium }

                    text: peopleModel.count == 0 ?
                          //: No available contacts
                          //% "You have no contacts yet"
                          qsTrId("contacts-la-no_contacts_available") :
                          //: Available contacts
                          //% "%n contact(s) already available."
                          qsTrId("contacts-la-n_contacts_available", peopleModel.count)
                }
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - x - Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font { pixelSize: Theme.fontSizeMedium }

                // TODO: remove mention of Bluetooth - JB#38055
                //: Prompt the user to choose an import option (text should match accept text label)
                //% "Choose 'Import' if you would like to import contacts using Accounts, from Bluetooth or other sources."
                text: qsTrId("contacts-la-import_prompt")
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - x - Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font { pixelSize: Theme.fontSizeMedium }

                //: Tells the user where to access import functionality
                //% "You can always import contacts from Settings / App settings / People."
                text: qsTrId("contacts-la-import_instructions")
            }
        }
    }

    PeopleModel {
        id: peopleModel
        filterType: PeopleModel.FilterAll
    }
    AccountManager {
        id: accountManager
    }
    AccountCreationManager {
        id: accountCreator
    }
    SignonUiService {
        // Note: this ID is required to have this name:
        id: jolla_signon_ui_service
        inProcessServiceName: "com.jolla.people"
        inProcessObjectPath: "/JollaPeopleSignonUi"
    }

    Component {
        id: importFromServices

        Page {
            SilicaFlickable {
                id: flickable
                width: parent.width
                height: parent.height
                contentWidth: width
                contentHeight: skipButton.y + skipButton.height + Theme.paddingMedium

                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: Theme.paddingLarge

                    PageHeader {}
                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - x - Theme.horizontalPageMargin
                        wrapMode: Text.Wrap
                        color: Theme.highlightColor
                        font { pixelSize: Theme.fontSizeLarge }

                        //: Import from services heading
                        //% "Import contacts from services"
                        text: qsTrId("contacts-la-import_from_services")
                    }
                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - x - Theme.horizontalPageMargin
                        wrapMode: Text.Wrap
                        color: Theme.highlightColor
                        font { pixelSize: Theme.fontSizeMedium }

                        //: Prompt the user to choose an import account (text should match import option label)
                        //% "Do you have a Google or Exchange account? If you don't have any suitable account, choose 'Import without services'."
                        text: qsTrId("contacts-la-import_select_account")
                    }
                    Column {
                        width: parent.width

                        ListModel {
                            id: accountsModel

                            Component.onCompleted: {
                                var availableProviders = accountManager.providerNames
                                if (availableProviders.indexOf('google') != -1) {
                                    append({
                                        //: Import using a Google account
                                        //% "Google"
                                        'name': qsTrId("contacts-la-google_account"),
                                        'providerName': 'google',
                                        'iconSource': 'image://theme/graphic-service-google',
                                        'highlightIcon': false
                                    })
                                }
                                if (availableProviders.indexOf('sailfisheas') != -1
                                        || availableProviders.indexOf('activesync') != -1) {
                                    var activeSyncProvider = availableProviders.indexOf('sailfisheas') != -1 ? 'sailfisheas' : 'activesync'
                                    append({
                                        //: Import using an Exchange account
                                        //% "Exchange"
                                        'name': qsTrId("contacts-la-exchange_account"),
                                        'providerName': activeSyncProvider,
                                        'iconSource': 'image://theme/graphic-service-exchange',
                                        'highlightIcon': false
                                    })
                                }
                                append({
                                    //: Import without services
                                    //% "Import without services"
                                    'name': qsTrId("contacts-la-without_services"),
                                    'iconSource': 'image://theme/icon-m-service-devices',
                                    'highlightIcon': true
                                })
                            }
                        }

                        Repeater {
                            model: accountsModel

                            BackgroundItem {
                                width: parent.width
                                height: Math.max(image.height, label.height) + 2*Theme.paddingMedium
                                opacity: enabled ? 1.0 : Theme.opacityLow

                                Image {
                                    id: image
                                    x: Theme.horizontalPageMargin
                                    width: Theme.iconSizeMedium
                                    height: width
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: model.iconSource + (model.highlightIcon ? ("?" + (highlighted ? Theme.highlightColor : Theme.primaryColor)) : "")
                                }
                                Label {
                                    id: label
                                    x: image.x + image.width + Theme.horizontalPageMargin
                                    width: parent.width - x - Theme.horizontalPageMargin
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                                    wrapMode: Text.Wrap
                                    text: model.name
                                }

                                onClicked: {
                                    if (model.providerName) {
                                        createAccount(model.providerName)
                                    } else {
                                        pageStack.animatorPush('wizard/ImportFromDevice.qml', {
                                            'importFromFile': importFromFile,
                                            'bluetoothPairing': bluetoothPairing,
                                            'createAccount': createAccount,
                                            'abandonImport': abandonImport
                                        })
                                    }
                                }
                            }
                        }
                    }
                }

                Button {
                    id: skipButton

                    anchors.horizontalCenter: parent.horizontalCenter
                    //: Cancel import procedure
                    //% "Skip importing"
                    text: qsTrId("contacts-bt-skip_importing")
                    y: Math.max(flickable.height - (height + Theme.itemSizeMedium), contentColumn.y + contentColumn.height + Theme.paddingLarge)

                    onClicked: abandonImport()
                }
            }
        }
    }
}
