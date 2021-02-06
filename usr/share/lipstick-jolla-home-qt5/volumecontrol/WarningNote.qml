/****************************************************************************
 **
 ** Copyright (c) 2013 - 2019 Jolla Ltd.
 ** Copyright (c) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1
import "../backgrounds"

SystemDialogLayout {
    id: root

    property bool initial

    contentHeight: content.height

    MenuBackground {
        width: content.width
        height: content.height
    }

    Column {
        id: content
        width: parent.width

        SystemDialogHeader {
            //% "To prevent possible hearing damage, do not listen at high volume levels for long periods."
            description: qsTrId("lipstick-jolla-home-la-audio_warning")
            topPadding: Theme.paddingLarge
        }

        SystemDialogIconButton {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.itemSizeHuge*1.5
            iconSource: (Screen.sizeCategory >= Screen.Large) ? "image://theme/icon-l-acknowledge"
                                                              : "image://theme/icon-m-acknowledge"
            text: root.initial
                    //% "Ok"
                  ? qsTrId("lipstick-jolla-home-la-user_acknowledge_long_listening_warning")
                    //% "I understand"
                  : qsTrId("lipstick-jolla-home-la-user_acknowledge_high_volume_warning")
            onClicked: {
                if (!root.initial) {
                    volumeControl.setWarningAcknowledged(true)
                }
                root.dismiss()
            }
        }
    }
}

