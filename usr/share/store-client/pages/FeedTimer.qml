import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

/* Feed Timer
 */
Timer {
    property var model
    property int pageStatus
    property var pullDownMenu

    property bool condition: model.count > 0 &&
                             !model.loading &&
                             pageStatus === PageStatus.Active &&
                             jollaStore.connectionState === JollaStore.Ready &&
                             jollaStore.isOnline &&
                             Qt.application.active &&
                             !pullDownMenu.active

    interval: 10000

    onConditionChanged: {
        if (condition) {
            restart()
        }
    }

    onTriggered: {
        if (!pullDownMenu.active && pageStatus === PageStatus.Active) {
            model.fetchContent(1)
        }
    }
}
