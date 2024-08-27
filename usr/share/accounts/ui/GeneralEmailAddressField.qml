/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0

Column {
    id: root

    property alias text: emailAddress.text
    property alias errorHighlight: emailAddress.errorHighlight

    width: parent.width

    TextField {
        id: emailAddress

        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhEmailCharactersOnly

        //% "Email address"
        label: qsTrId("components_accounts-la-genericemail_email_address")

        //% "Email address is required"
        description: errorHighlight ? qsTrId("components_accounts-la-email_address_required") : ""
    }

    ValidatedTextInput {
        textField: emailAddress
        autoValidate: true
        autoValidationTimeout: 100

        onValidationRequested: {
            if (emailAddress.text.toLowerCase().indexOf("@gmail.") > 0) {
                //: Describes how Google users need to update security settings to allow accounts 
                //: to be created on Sailfish OS
                //% "Gmail login requires that your Google account's security settings are set to "
                //% "allow 'Less secure app access'. Note that for improved security, it is "
                //% "recommended to create a 'Google' account instead of an email-only account."
                progressText = qsTrId("settings_accounts-generic_google_account_creation_warning")
            } else if (emailAddress.text.toLowerCase().indexOf("@yahoo.") > 0) {
                //: Describes how Yahoo! users need to update security settings to allow accounts 
                //: to be created on Sailfish OS
                //% "Yahoo! Mail login requires that your Yahoo! account's security settings are "
                //% "set to allow 'Less secure app access'."
                progressText = qsTrId("settings_accounts-generic_yahoo_account_creation_warning")
            } else {
                progressText = ""
            }
        }
    }
}
