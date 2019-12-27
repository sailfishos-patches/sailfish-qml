/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    id: column

    property var fields: ({})
    property var formData: ({})
    property Item focusField

    signal enterKeyClicked

    width: parent.width

    onFieldsChanged: column.buildForm()

    function focus() {
        if (focusField) {
            focusField.forceActiveFocus()
        }
    }
    function cancel() {
        for (var i = 0; i < children.length; ++i) {
            if (children[i].text !== undefined) {
                children[i].text = ""
            }
        }
    }
    function clear() {
        if (focusField) {
            focusField.focus = false
        }
        focusField = null
        for (var i = 0; i < column.children.length; i++) {
            column.children[i].destroy()
        }
    }

    function buildForm() {
        var orderedFields = ["Name", "SSID", "Identity", "Passphrase",
                             "PreviousPassphrase", "WPS", "Username",
                             "Password"]
        var current

        clear()
        if (credentialField.status == Component.Error) {
            console.warn("Credential field loading failed", credentialField.errorString())
        }

        var previousFieldItem = null
        for (var i = 0; i < orderedFields.length; i++) {
            current = orderedFields[i]
            if (fields[current] !== undefined && fields[current]["Requirement"] === "mandatory") {
                var fieldItem = credentialField.createObject(column, {"type": current})
                if (!focusField) {
                    focusField = fieldItem
                }
                if (previousFieldItem)
                    previousFieldItem.nextField = fieldItem
                previousFieldItem = fieldItem
            }
        }
    }

    function localizeCredential(str) {
        // localize connman credential string
        if (str === "Passphrase") {
            return ""
        } else if (str === "Name") {
            //: Name for hidden network
            //% "Name"
            return qsTrId("lipstick-jolla-home-la-name_query")
        } else if (str === "SSID") {
            //: SSID query for a hidden network
            //% "SSID"
            return qsTrId("lipstick-jolla-home-la-ssid_query")
        } else if (str === "Identity") {
            //: 802.x Identity query
            //% "Identity"
            return qsTrId("lipstick-jolla-home-la-identity_query")
        } else if (str === "WPS") {
            //% "WPS"
            return qsTrId("lipstick-jolla-home-la-wps_query")
        } else if (str === "Username") {
            //: Username for WISPr authentication
            //% "Username"
            return qsTrId("lipstick-jolla-home-la-username_query")
        } else if (str === "Password") {
            return ""
        }

        console.warn("Unknown credential type: " + str)
        return "!!" + str
    }

    Component.onDestruction: column.clear()

    Component {
        id: credentialField
        PasswordField {
            id: textField
            property string type
            property Item nextField

            showEchoModeToggle: type === "Passphrase" || type === "Password"
            passwordEchoMode: showEchoModeToggle ? TextInput.Password : TextInput.Normal
            _appWindow: undefined // suppresses warnings, TODO: fix password field magnifier
            color: Theme.highlightColor
            cursorColor: Theme.highlightColor
            placeholderColor: Theme.secondaryHighlightColor
            textMargin: 2*Theme.paddingLarge
            textTopMargin: Theme.paddingLarge
            height: implicitHeight + Theme.paddingSmall // take into account inc

            label: column.localizeCredential(type)
            placeholderText: {
                var passphraseType

                if (type === "Passphrase") {
                    passphraseType = form.fields["Passphrase"]["Type"]

                    if (passphraseType === "psk") {
                        //% "Enter PSK passphrase"
                        return qsTrId("lipstick-jolla-home-ph-psk_passphrase")
                    } else if (passphraseType === "wep") {
                        //% "Enter WEP key"
                        return qsTrId("lipstick-jolla-home-ph-wep")
                    } else {
                        //% "Enter Passphrase"
                        return qsTrId("lipstick-jolla-home-ph-passphrase")
                    }
                } else {
                    //% "Enter %1"
                    return qsTrId("lipstick-jolla-home-ph-enter_field").arg(column.localizeCredential(type))
                }
            }
            onTextChanged: {
                var tmp = column.formData

                if (column.formData === undefined) {
                    return
                }
                tmp[type] = text
                column.formData = tmp
            }

            EnterKey.iconSource: nextField ? "image://theme/icon-m-enter-next" : "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: {
                if (nextField)
                    nextField.focus = true
                else
                    column.enterKeyClicked()
            }
        }
    }
}

