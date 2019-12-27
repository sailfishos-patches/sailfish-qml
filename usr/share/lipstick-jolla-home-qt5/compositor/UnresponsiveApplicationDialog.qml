/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import org.nemomobile.lipstick 0.1
import com.jolla.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import "../systemwindow"
import "../compositor"

SystemWindow {
    id: unresponsiveApplicationDialog

    property Item window
    opacity: _windowOpacity
    enabled: windowVisible
    fadeEnabled: true
    contentHeight: content.height

    SystemDialogLayout {
        contentHeight: content.height
        onDismiss: {
            unresponsiveApplicationDialog.shouldBeVisible = false
            unresponsiveApplicationDialog.pingWindow()
        }

        BlurredBackground {
            anchors.fill: content
            backgroundItem: Lipstick.compositor.blurSource
        }

        Column {
            id: content
            width: parent.width

            SystemDialogHeader {
                id: dialogHeader

                property string titleText: window ? (window.title || JollaSystemInfo.desktopNameForPid(window.processId))
                                                  : ""
                //% "%1 is not responding"
                title: qsTrId("lipstick-jolla-home-he-not_responding").arg(titleText.length > 0
                                                                           ? titleText
                                                                           : //% "Unnamed application"
                                                                             qsTrId("lipstick-jolla-home-he-unnamed_application"))

                //% "You can either wait or close the application."
                description: qsTrId("lipstick-jolla-home-la-application_hanged_description")
                topPadding: transpose ? Theme.paddingLarge : 2*Theme.paddingLarge
            }
            Row {
                id: buttonRow

                property real buttonWidth: Math.min(parent.width / 2, Theme.itemSizeHuge*1.5)

                anchors.horizontalCenter: parent.horizontalCenter
                height: Math.max(wait.implicitHeight, close.implicitHeight)

                SystemDialogIconButton {
                    id: wait

                    width: buttonRow.buttonWidth
                    height: parent.height
                    //% "Wait"
                    text: qsTrId("lipstick-jolla-home-bt-wait")
                    iconSource: (Screen.sizeCategory >= Screen.Large) ? "image://theme/icon-l-clock"
                                                                      : "image://theme/icon-m-clock"
                    onClicked: {
                        unresponsiveApplicationDialog.shouldBeVisible = false
                        unresponsiveApplicationDialog.pingWindow()
                    }
                }
                SystemDialogIconButton {
                    id: close

                    width: buttonRow.buttonWidth
                    height: parent.height
                    //% "Close"
                    text: qsTrId("lipstick-jolla-home-bt-close")
                    iconSource: (Screen.sizeCategory >= Screen.Large) ? "image://theme/icon-l-dismiss"
                                                                      : "image://theme/icon-m-dismiss"
                    onClicked: {
                        unresponsiveApplicationDialog.shouldBeVisible = false
                        window.terminateProcess(1000)
                        console.log("User terminated the unresponsive application", "\"" + dialogHeader.titleText + "\"", "with PID", window.processId)
                    }
                }
            }
        }
    }

    Timer {
        id: waitForPongTimer
        interval: 3000
        onTriggered: {
            if (window) {
                unresponsiveApplicationDialog.shouldBeVisible = true
                console.log("Application", "\"" + dialogHeader.titleText + "\"", "with PID", window.processId, "is not responding")
            }
        }
    }

    Connections {
        target: window ? window.surface : unresponsiveApplicationDialog
        ignoreUnknownSignals: true
        onPong: {
            if (unresponsiveApplicationDialog.shouldBeVisible) {
                console.log("Unresponsive application", "\"" + dialogHeader.titleText + "\"",
                            "with PID", window.processId, "has started responding again")
            }

            unresponsiveApplicationDialog.shouldBeVisible = false
            waitForPongTimer.stop()
            pingWindowTimer.start()
        }
    }

    function pingWindow() {
        waitForPongTimer.restart()
        window.surface.ping()
    }

    Timer {
        id: pingWindowTimer
        interval: 5000
        onTriggered: if (window) pingWindow()
    }

    onWindowChanged: {
        unresponsiveApplicationDialog.shouldBeVisible = false
        if (window && window.surface) {
            pingWindow()
        } else {
            pingWindowTimer.stop()
            waitForPongTimer.stop()
        }
    }
}
