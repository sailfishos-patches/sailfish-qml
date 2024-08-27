/* Copyright (c) 2018 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 * License: Proprietary
 */
 
 import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

SystemDialog {
    id: dialog

    signal requestInstall

    title: packageName
    contentHeight: contentColumn.height

    Column {
        id: contentColumn
        width: parent.width

        SystemDialogHeader {
            id: header
            title: packageName
            description: packageSummary
        }
        

        Label {
            width: header.width
            anchors.horizontalCenter: parent.horizontalCenter
            visible: packageVersion != ""
            color: Theme.highlightColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            font.pixelSize: Theme.fontSizeExtraSmall
            //: %1 replaced with package version
            //% "Version %1"
            text: qsTrId("installation_handler-la-version").arg(packageVersion)
        }

        SystemDialogIconButton {
            id: installButton

            width: header.width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            //: Install button in the package sideloading system dialog.
            //% "Install"
            text: qsTrId("installation_handler-bt-sideload_install")
            iconSource: (Screen.sizeCategory >= Screen.Large) ? "image://theme/icon-l-add"
                                                              : "image://theme/icon-m-add"
            onClicked: {
                dialog.requestInstall()
                dialog.lower()
            }
        }
    }
}
