import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.voicecall.settings.translations 1.0

Column {
    id: busyIndicator
    property bool running
    opacity: running ? 1.0 : 0.0
    Behavior on opacity { FadeAnimation {} }
    visible: opacity > 0.0
    spacing: Theme.paddingLarge
    Label {
        id: busyLabel
        //% "Retrieving settings"
        text: qsTrId("settings_voicecall-la-retrieving_settings")
        anchors.horizontalCenter: parent.horizontalCenter
        font.pixelSize: Theme.fontSizeLarge
        color: Theme.highlightColor
    }
    BusyIndicator {
        running: parent.visible
        size: BusyIndicatorSize.Large
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
