import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

CoverBackground {
    id: cover
    
    signal searchActionTriggered()

    Image {
        anchors.fill: parent
        source: "image://theme/graphic-cover-store-splash"
    }

    CoverActionList {
        enabled: jollaStore.connectionState === JollaStore.Ready

        CoverAction {
            iconSource: "image://theme/icon-cover-search"
            onTriggered: {
                cover.searchActionTriggered()
            }
        }
    }
}
