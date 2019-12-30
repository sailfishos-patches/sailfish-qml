import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

HighlightImage {
    property string icon
    property bool pressed
    property real size: Theme.iconSizeLauncher

    sourceSize.width: size
    sourceSize.height: size
    width: size
    height: size
    highlighted: pressed

    monochromeWeight: colorWeight
    highlightColor: Theme.highlightBackgroundColor

    property string _source: {
        if (icon.indexOf(':/') !== -1 || icon.indexOf("data:image/png;base64") === 0) {
            return icon
        } else if (icon.indexOf('/') === 0) {
            return 'file://' + icon
        } else if (icon.length) {
            return 'image://theme/' + icon
        } else {
            return ""
        }
    }

    readonly property bool haveDesktop: model && model.object && model.object.filePath
    readonly property string objectKey: haveDesktop ? model.object.filePath : icon
    readonly property string fileName: objectKey.split("/").pop().split(".")[0]

    source: iconLoader.status == Loader.Ready ? "" : _source

    ConfigurationValue {
        id: launcherConfig
        key: "/apps/lipstick-jolla-home-qt5/icons/%1".arg(fileName)
        defaultValue: false
    }

    Loader {
        id: iconLoader
        anchors.fill: parent
        source: Qt.resolvedUrl("LauncherIcon-%1.qml".arg(fileName))
        active: launcherConfig.value
    }
}
