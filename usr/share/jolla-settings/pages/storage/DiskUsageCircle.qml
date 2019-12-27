import QtQuick 2.0
import Sailfish.Silica 1.0

ProgressCircleBase {

    property bool highlighted
    property bool alternateColors

    readonly property color primaryColor: {
        if (!enabled) {
            return Theme.rgba(Theme.highlightColor, Theme.opacityLow)
        } else if (highlighted) {
            return Theme.highlightColor
        } else {
            return Theme.primaryColor
        }
    }

    readonly property color secondaryColor: {
        if (!enabled) {
            return Theme.rgba(Theme.highlightColor, Theme.opacityFaint)
        } else if (highlighted) {
            return Theme.rgba(Theme.highlightColor, Theme.opacityHigh)
        } else {
            return Theme.rgba(Theme.primaryColor, Theme.opacityLow)
        }
    }

    backgroundColor: alternateColors ? primaryColor : secondaryColor
    progressColor: alternateColors ? secondaryColor : primaryColor

    height: width
    width: implicitWidth
    implicitWidth: Theme.itemSizeHuge
    borderWidth: Math.round(Theme.paddingLarge/3)
}
