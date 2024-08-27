import QtQuick 2.0
import Sailfish.Silica 1.0
import "../pages"

CoverBackground {
    OpacityRampEffect {
        direction: OpacityRamp.RightToLeft
        sourceItem: calculationsListView
        offset: 0.5
    }
    CalculationsListView {
        id: calculationsListView

        coverMode: true
        anchors {
            fill: parent
            rightMargin: Theme.paddingLarge
            bottomMargin: Theme.paddingLarge
        }
    }
}
