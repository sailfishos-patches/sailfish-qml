import QtQuick 2.0
import Sailfish.Silica 1.0

Image {
    property url icon

    fillMode: Image.PreserveAspectFit
    source: icon + "?" + (Theme.colorScheme == Theme.LightOnDark
                          ? Theme.highlightColor
                          : Theme.highlightFromColor(Theme.highlightColor, Theme.LightOnDark))
    scale: 0.75
}
