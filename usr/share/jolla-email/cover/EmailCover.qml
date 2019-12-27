/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: emailCover

    Image {
        visible: app.numberOfAccounts > 0 && !app.accountsManagerActive
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: sourceSize.height * width / sourceSize.width
        source: "image://theme/graphic-cover-email-background"
        opacity: 0.1
    }

    CoverPlaceholder {
        id: placeholder

        //% "Create account"
        text: qsTrId("email-la-create_account")
        icon.source: "image://theme/icon-launcher-email"
        visible: app.numberOfAccounts === 0 || app.accountsManagerActive
    }

    Loader {
        id: coverLoader
        anchors.fill: parent
        asynchronous: true
        source: {
            if (placeholder.visible)
                return ""

            switch (app.coverMode) {
            case "mainView":
                return "MainViewCover.qml"
            case "mailViewer":
                return "MailViewerCover.qml"
            case "mailEditor":
                return "MailEditorCover.qml"
            default:
                console.warn("Invalid cover mode", app.coverMode)
                return ""
            }
        }

        onStatusChanged: {
            if (status == Loader.Error && sourceComponent) {
                console.log(sourceComponent.errorString())
            }
        }
    }
}
