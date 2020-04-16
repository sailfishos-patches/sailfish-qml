import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0

LinearGradient {
    opacity: Theme.opacityLow
    height: Theme.paddingSmall/3
    start: Qt.point(0, 0)
    end: Qt.point(parent.width, 0)
    gradient: Gradient {
        GradientStop { position: 0.0; color: Theme.rgba(Theme.primaryColor, Theme.opacityFaint) }
        GradientStop { position: 0.5; color: Theme.rgba(Theme.primaryColor, Theme.opacityHigh) }
        GradientStop { position: 1.0; color: Theme.rgba(Theme.primaryColor, Theme.opacityFaint) }
    }
}
