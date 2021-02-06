import QtQuick 2.1
import Sailfish.Silica 1.0
import "pages"

ApplicationWindow
{
    initialPage: Component { MainPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")

    property var colors : [ "#ff0080", "#ff0000", "#ff8000", "#ffff00", "#00ff00",
                            "#00ff80", "#00ffff", "#0000ff", "#8000ff", "#ff00ff",
                            "#000000", "#ffffff" ]

    onApplicationActiveChanged: helper.checkOverlay()
}


