import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

/* Item showing the install progress.
 */
Rectangle {
    property int appState
    property int progress

    anchors.fill: parent
    color: Theme.rgba(Theme.highlightDimmerColor, Theme.opacityHigh)

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        running: appState === ApplicationState.Uninstalling || (progress > 0 && progress < 100)
    }

    Image {
        anchors.centerIn: busyIndicator
        source: (appState !== ApplicationState.Uninstalling && progress < 50)
                ? "image://theme/icon-s-cloud-download"
                : ""
    }

    Label {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: busyIndicator.bottom
            topMargin: Theme.paddingMedium
        }
        font.pixelSize: Theme.fontSizeTiny
        text: packageHandler.applicationStateName(appState, progress)
    }
}
