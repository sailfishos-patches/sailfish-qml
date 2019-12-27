import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    anchors.fill: parent
    active: counter.active
    sourceComponent: Component {
        Item {
            anchors.fill: parent

            InteractionHintLabel {
                //% "Swipe left to access the sub-categories"
                text: qsTrId("jolla-store-la-categories_attached_page_hint")
                anchors.bottom: parent.bottom
                opacity: touchInteractionHint.running ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation { duration: 1000 } }
            }

            TouchInteractionHint {
                id: touchInteractionHint
                property bool pageActive: page.status === PageStatus.Active &&
                                          Qt.application.active &&
                                          page.canNavigateForward &&
                                          !page.loading

                onPageActiveChanged: {
                    if (pageActive) {
                        restart()
                        pageActive = false
                        counter.increase()
                    }
                }

                parent: page
                direction: TouchInteraction.Left
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    FirstTimeUseCounter {
        id: counter
        limit: 2
        key: "/sailfish/store/categories_attached_page_hint_count"
    }
}
