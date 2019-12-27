import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import Sailfish.Telephony 1.0

import "contactcardmodelfactory.js" as ModelFactory
import "numberutils.js" as NumberUtils

ExpandingDelegate {
    id: detailItem

    property bool hidePhoneActions
    property bool disablePhoneActions

    property bool _disableActionButtons

    // Signals to tell that some contact card action item has been clicked.
    // Yep, it's a string because the phone number can start with the '+' char.
    signal callClicked(string number, string connection, string modemPath)
    signal smsClicked(string number, string connection)
    signal emailClicked(string email)
    signal imClicked(string localUid, string remoteUid)
    signal addressClicked(string address, variant addressParts)
    signal copyToClipboardClicked(string detailValue, variant detailParts)
    signal websiteClicked(string url)
    signal dateClicked(variant date)
    signal editDetailClicked()

    function updateDetailActions() {
        detailActions = ModelFactory.getDetailsActions(detailType)
    }

    function handleActionClicked(actionType) {
        var actionValue = detailValue

        switch (actionType) {
        case "call":
            if (Telephony.voiceSimUsageMode == Telephony.AlwaysAskSim) {
                menu = simSelectorComponent.createObject(null)
                openMenu()
            } else {
                callClicked(actionValue, "gsm", "")
            }
            break;
        case "sms":
            actionValue = NumberUtils.sanitizePhoneNumber(actionValue)
            smsClicked(actionValue, "gsm")
            break;
        case "email":
            emailClicked(actionValue)
            break;
        case "im":
            imClicked(detailData.localUid, detailData.remoteUid)
            break;
        case "address":
            addressClicked(actionValue, detailData)
            break;
        case "copyToClipboard":
            copyToClipboardClicked(actionValue, detailData)
            break;
        case "website":
            websiteClicked(actionValue)
            break;
        case "date":
            dateClicked(detailData.date)
            break;
        case "editDetail":
            editDetailClicked()
            break;
        }
    }

    Component.onCompleted: {
        if (!hidePhoneActions || detailType !== "phone") {
            updateDetailActions()
        }
    }

    openMenuOnPressAndHold: false
    menu: defaultDetailContextMenuComponent
    onPressAndHold: {
        menu = defaultDetailContextMenuComponent
        openMenu()
    }

    onActionClicked: {
        if (actionType.length === 0) {
            menu = defaultDetailContextMenuComponent
            openMenu()
        } else {
            handleActionClicked(actionType)
        }
    }

    // In case modem/SIM is ready later
    onHidePhoneActionsChanged: {
        if (!hidePhoneActions && detailType === "phone" && detailActions.length == 0) {
            updateDetailActions()
        }
    }
    onDisablePhoneActionsChanged: {
        if (detailType === "phone") {
            _disableActionButtons = disablePhoneActions
        }
    }

    Component {
        id: simSelectorComponent
        ContextMenu {
            id: simContextMenu
            onClosed: destroy()
            SimPicker {
                onSimSelected: {
                    var actionValue = NumberUtils.sanitizePhoneNumber(detailValue)
                    callClicked(actionValue, "gsm", modemPath)
                    simContextMenu.close()
                }
            }
        }
    }

    Component {
        id: defaultDetailContextMenuComponent
        ContextMenu {
            id: detailContextMenu
            onClosed: destroy()
            MenuItem {
                //% "Copy to clipboard"
                text: qsTrId("components_contacts-action-copy_to_clipboard")
                onClicked: {
                    actionClicked("copyToClipboard")
                    detailContextMenu.close()
                }
            }
            MenuItem {
                //: Edit a particular detail value, e.g. phone number or email address
                //% "Edit"
                text: qsTrId("components_contacts-me-edit_detail")
                onClicked: {
                    actionClicked("editDetail")
                    detailContextMenu.close()
                }
            }
        }
    }
}
