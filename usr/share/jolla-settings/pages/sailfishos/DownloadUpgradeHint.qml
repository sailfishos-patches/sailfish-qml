import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    anchors.fill: parent
    active: counter.active
    sourceComponent: Component {
        Item {
            anchors.fill: parent

            InteractionHintLabel {
                //% "Pull down to download system update"
                text: qsTrId("settings_sailfishos-la-download_system_update_hint")
                anchors.bottom: parent.bottom
                opacity: touchInteractionHint.running ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation { duration: 1000 } }
            }

            Connections {
                target: storeIf
                onMayDownloadChanged: {
                    // The store upgrade status property fluctuating between UpdateAvailable
                    // and PreparingForUpdate. Using a timer as a work-around for not
                    // triggering the interaction hint too early.
                    kludgeTimer.restart()
                }
            }

            Timer {
                id: kludgeTimer
                interval: 100
                onTriggered: touchInteractionHint.mayDownload = storeIf.mayDownload
            }

            TouchInteractionHint {
                id: touchInteractionHint
                property bool mayDownload
                property bool pageActive: page.status === PageStatus.Active && Qt.application.active && mayDownload

                onPageActiveChanged: {
                    if (pageActive) {
                        restart()
                        pageActive = false
                        counter.increase()
                    }
                }

                parent: page
                direction: TouchInteraction.Down
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    FirstTimeUseCounter {
        id: counter
        limit: 3
        key: "/sailfish/store/download_upgrade_hint_count"
    }
}
