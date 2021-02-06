import QtQml 2.2
import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0
import "../pages"

CoverBackground {
    id: cover

    signal searchActionTriggered()

    Image {
        opacity: !appData.processing ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {}}
        anchors.fill: parent
        source: "image://theme/graphic-cover-store-splash"
    }

    CoverActionList {
        enabled: jollaStore.connectionState === JollaStore.Ready && !appData.processing

        CoverAction {
            iconSource: "image://theme/icon-cover-search"
            onTriggered: {
                cover.searchActionTriggered()
            }
        }
    }

    ApplicationData {
        id: appData

        property bool processing
        onValidChanged: {
            if (valid) {
                processing = Qt.binding(function () { return appData.state === ApplicationState.Installing
                                                      || appData.state === ApplicationState.Updating
                                                      || appData.state === ApplicationState.Uninstalling
                                                      || showInstalledTimer.running})
            } else {
                processing = false
            }
        }
    }

    Timer {
        id: showInstalledTimer
        interval: 2000
        running: appData.state === ApplicationState.Installed
    }

    Instantiator {
        model: installedModel
        QtObject {
            readonly property bool active: appData.application === model.uuid
            readonly property int state: model.appState
            readonly property int progress: model.progress
            property bool coverProcessing: appData.processing

            onStateChanged: update()
            onCoverProcessingChanged: if (!coverProcessing) update()

            function update() {
                var processing = state === ApplicationState.Installing
                        || state === ApplicationState.Updating
                        || state === ApplicationState.Uninstalling
                if (processing && !appData.processing) {
                    appData.application = model.uuid
                }
            }
        }
    }

    Loader {
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        active: appData.application.length > 0
        sourceComponent: Column {
            opacity: appData.processing ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {}}

            width: parent.width
            height: implicitHeight
            Item {
                width: busyIndicator.width * busyIndicator.scale
                height: busyIndicator.height * busyIndicator.scale
                anchors.horizontalCenter: parent.horizontalCenter

                BusyIndicator {
                    id: busyIndicator
                    size: BusyIndicatorSize.Large
                    _forceAnimation: cover.status === Cover.Active
                    running: (appData.state === ApplicationState.Installing
                              || appData.state === ApplicationState.Updating) && (appData.progress === 0 || appData.progress === 100)
                             || appData.state === ApplicationState.Uninstalling
                    color: Theme.primaryColor
                    scale: 1.4 // TODO: BusyIndicatorSize.ExtraLarge needed
                    anchors.centerIn: parent
                    transformOrigin: Item.Center
                }

                ProgressCircle {
                    anchors.fill: parent
                    opacity: (appData.progress > 0 && appData.progress < 100) && appData.state !== ApplicationState.Uninstalling ? 1.0 : 0.0
                    Behavior on opacity { FadeAnimator {} }
                    progressColor: palette.highlightColor
                    backgroundColor: palette.highlightDimmerColor
                    value: (appData.progress % 50) / 50.0
                    borderWidth: Math.round(Theme.paddingSmall/2)
                }

                AppImage {
                    height: width
                    width: Theme.iconSizeLauncher
                    image: appData.icon !== "" ? appData.icon : "image://theme/icon-store-appData-default"
                    anchors.centerIn: parent
                }
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            Label {
                font.bold: true
                width: parent.width - 2*x
                x: Theme.paddingLarge
                horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                text: appData.title
                truncationMode: TruncationMode.Fade
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            Label {
                color: Theme.secondaryColor
                width: parent.width - 2*x
                x: Theme.paddingLarge
                horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                text: appData.processing ? packageHandler.applicationStateName(appData.state, appData.progress)
                                     : " "
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeSmall
                fontSizeMode: Text.HorizontalFit
            }

            Item {
                width: 1
                height: Theme.paddingSmall
            }

            Label {
                property bool active: appData.size > 0 && appData.progress > 0 && appData.progress < 50 && appData.state !== ApplicationState.Uninstalling

                //: Download progress fraction, e.g. 25.7MB / 44.3MB
                //% "%1 / %2"
                text: active ? qsTrId("jolla-store-la-download_progress")
                                   .arg(Format.formatFileSize(appData.progress / 50.0 * appData.size))
                                   .arg(Format.formatFileSize(appData.size))
                             : " "

                x: Theme.paddingLarge
                width: parent.width - 2*x
                color: Theme.secondaryColor
                fontSizeMode: Text.HorizontalFit
                horizontalAlignment: Text.AlignHCenter
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeSmall
            }
        }
    }
}
