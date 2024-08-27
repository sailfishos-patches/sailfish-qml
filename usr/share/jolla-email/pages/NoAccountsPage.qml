/*
 * Copyright (c) 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.email 1.1
import Sailfish.Policy 1.0

Page {
    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            visible: AccessPolicy.accountCreationEnabled
            MenuItem {
                //: Add account menu item
                //% "Add account"
                text: qsTrId("jolla-email-me-add_account")
                onClicked: {
                    app.showAccountsCreationDialog()
                }
            }
        }

        PageHeader {
            //: Email page header
            //% "Mail"
            title: qsTrId("email-he-email")
        }

        NoAccountsPlaceholder {
            enabled: true
        }
    }
}
