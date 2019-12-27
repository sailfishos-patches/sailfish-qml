import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0

DetailFieldDelegate {
    id: root

    property alias presenceState: indicator.presenceState

    metadataLabel.width: Math.min(metadataLabel.implicitWidth,
                                  root.width - indicator.width - Theme.paddingMedium)

    ContactPresenceIndicator {
        id: indicator

        x: root.metadataLabel.x + root.metadataLabel.width + Theme.paddingMedium
        y: root.metadataLabel.y + root.metadataLabel.height/2 - height/2
    }
}
