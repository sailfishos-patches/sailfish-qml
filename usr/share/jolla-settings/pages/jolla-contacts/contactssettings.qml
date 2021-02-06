import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import org.nemomobile.configuration 1.0
import Nemo.DBus 2.0
import org.nemomobile.ofono 1.0
import MeeGo.QOfono 0.2
import com.jolla.contacts.settings 1.0
import com.jolla.settings 1.0

// ### UI layout is all just placeholder for an actual design so that the feature is available
// and people can import contacts somehow.
ApplicationSettings {
    SectionHeader {
        //% "Names"
        text: qsTrId("contacts_settings-la-names")
    }

    TextSwitch {
        //% "Show family name first"
        text: qsTrId("contacts_settings-bt-order_switch")

        ConfigurationValue {
            id: orderConfig
            key: "/org/nemomobile/contacts/display_label_order"
            defaultValue: 0
        }

        Component.onCompleted: {
            checked = (orderConfig.value == 1)
        }
        onCheckedChanged: {
            orderConfig.value = (checked ? 1 : 0)
        }
    }

    TextSwitch {
        //% "Sort by family name"
        text: qsTrId("contacts_settings-bt-sort_switch")

        ConfigurationValue {
            id: sortConfig
            key: "/org/nemomobile/contacts/sort_property"
            defaultValue: "firstName"
        }

        ConfigurationValue {
            id: groupConfig
            key: "/org/nemomobile/contacts/group_property"
            defaultValue: "firstName"
        }

        Component.onCompleted: {
            checked = (sortConfig.value == "lastName" && groupConfig.value == "lastName")
        }
        onCheckedChanged: {
            sortConfig.value = (checked ? "lastName" : "firstName")
            groupConfig.value = (checked ? "lastName" : "firstName")
        }
    }

    SectionHeader {
        //% "SIM contacts"
        text: qsTrId("contacts_settings-cb-sim_contacts")
        visible: modemManager.availableModems.length > 0
    }

    TextSwitch {
        enabled: simListModel.count > 0
        //% "Show SIM contacts automatically"
        text: qsTrId("contacts_settings-cb-show_sim")
        //% "Display SIM contacts in the People app even if they have not been imported"
        description: qsTrId("contacts_settings-cb-show_sim_description")

        Component.onCompleted: checked = (transientImportConfig.value == 1)
        onCheckedChanged: transientImportConfig.value = (checked ? 1 : 0)
        ConfigurationValue {
            id: transientImportConfig
            key: "/org/nemomobile/contacts/sim/transient_import"
            defaultValue: 1
        }
    }

    SectionHeader {
        //% "Import contacts"
        text: qsTrId("contacts_settings-cb-import")
    }

    ImportButton {
        //: Can be clicked to start the contacts import wizard
        //% "Start import wizard"
        text: qsTrId("contacts_settings-la-import_wizard")
        iconSource: "image://theme/icon-m-wizard"
        onClicked: {
            contactsDbusIface.call('importWizard', [])
        }
    }

    Repeater {
        model: simListModel
        delegate: ImportButton {
            text: {
                var modemIndex = simManager.ready ? simManager.indexOfModem(model.path) : -1
                var simName = modemIndex >= 0 ? simManager.simNames[modemIndex] : ""
                return simName
                          //: Can be clicked to import contacts from a SIM card. %1 = SIM card name
                          //% "From %1"
                        ? qsTrId("contacts_settings-la-import_from_sim").arg(simName)
                          //: Can be clicked to import contacts from a SIM card
                          //% "From SIM"
                        : qsTrId("contacts_settings-la-import_from_sim_unnamed")
            }
            iconSource: "image://theme/icon-m-pin"
            onClicked: {
                contactsDbusIface.call('importContactsFromSim', [model.path])
            }
        }
    }

    ImportButton {
        //: Can be clicked to import contacts from a contact file
        //% "From contact file"
        text: qsTrId("contacts_settings-la-import_from_contact_file")
        iconSource: "image://theme/icon-m-device-upload"
        onClicked: {
            var obj = pageStack.animatorPush(Qt.resolvedUrl("ContactFilePickerPage.qml"))
            obj.pageCompleted.connect(function(page) {
                page.onFileSelected.connect(function(fileUrl) {
                    pageStack.pop()
                    contactsDbusIface.call('importContactFile', ['' + fileUrl])
                })
            })
        }
    }

    PullDownMenu {
        MenuItem {
            //: Remove all contacts stored on the device
            //% "Remove all contacts"
            text: qsTrId("contacts_settings-me-remove_all_contacts")
            onClicked: pageStack.animatorPush(removeContactsComponent)
        }
    }

    Component {
        id: removeContactsComponent

        Page {
            Column {
                width: parent.width

                PageHeader {
                    //% "Remove contacts"
                    title: qsTrId("contacts_settings-he-remove_all_contacts")
                }

                Button {
                    //% "Remove device contacts"
                    text: qsTrId("contacts_settings-bt-remove_all")
                    anchors.horizontalCenter: parent.horizontalCenter

                    onClicked: {
                        pageStack.pop()
                        var iface = contactsDbusIface
                        //% "Deleted device contacts"
                        Remorse.popupAction(root, qsTrId("contacts_settings-la-deleted_device_contacts"),
                                            function() { iface.call('removeAllDeviceContacts', []) })
                    }
                }

                Item {
                    width: parent.width
                    height: Theme.paddingLarge
                }

                Text {
                    x: Theme.paddingLarge
                    width: parent.width - 2 * Theme.paddingLarge
                    wrapMode: Text.Wrap
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.highlightColor

                    //% "Affects all contacts in the device not synced from an external service. Any synced contacts can be removed by changing the settings for the relevant account."
                    text: qsTrId("contacts_settings-la-remove_description")
                }
            }
        }
    }

    DBusInterface {
        id: contactsDbusIface
        service: "com.jolla.contacts.ui"
        path: "/com/jolla/contacts/ui"
        iface: "com.jolla.contacts.ui"
    }

    OfonoModemManager {
        id: modemManager
    }

    OfonoSimListModel {
        id: simListModel
    }

    SimManager {
        id: simManager
    }
}
