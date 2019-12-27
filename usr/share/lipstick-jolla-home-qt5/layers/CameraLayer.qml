import QtQuick 2.6
import QtQuick.Window 2.1 as QtQuick
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1
import org.nemomobile.devicelock 1.0
import com.jolla.lipstick 0.1
import "../windowwrappers"
import "../switcher"
import "../camera"

EdgeLayer {
    id: cameraLayer

    property alias application: cameraLauncher
    readonly property bool canActivate: cameraLauncher.isValid && Desktop.deviceLockState <= DeviceLock.Locked
                                        && AccessPolicy.cameraEnabled
                                        && Lipstick.compositor.systemInitComplete && Desktop.settings.lock_screen_camera

    objectName: "cameraLayer"

    edge: PeekFilter.Bottom
    window: windowWrapper
    enabled: canActivate && Lipstick.compositor.peekingLayer.isFullScreen

    edgeFilter {
        onGestureTriggered: {
            if (cameraLayer.active) {
                Lipstick.compositor.setCurrentWindow(Lipstick.compositor.obscuredWindow)
            } else {
                Lipstick.compositor.setCurrentWindow(windowWrapper)
                lipstickSettings.lockscreenVisible = false

                if (windowWrapper.window) {
                    Lipstick.compositor.raiseWindow(windowWrapper.window)
                } else if (!cameraLauncher.isLaunching) {
                    startupWatcher.running = true
                    cameraLauncher.launchApplication()
                }
            }
        }
    }

    onClosed: {
        if (active) {
            Lipstick.compositor.setCurrentWindow(Lipstick.compositor.obscuredWindow)
        }
    }

    Rectangle {
        parent: cameraLayer.underlayItem
        anchors.fill: parent
        color: "black"
    }

    WindowWrapper {
        id: windowWrapper

        objectName: "cameraWindow"
        windowType: WindowType.Camera
        exposed: cameraLayer.visible

        onWindowChanged: {
            if (window) {
                startupWatcher.running = false
            }
        }
    }

    Loader {
        active: Desktop.settings.lock_screen_camera
        CameraSplash {
            id: splash
            parent: cameraLayer.overlayItem

            isPortrait: Lipstick.compositor.sensorOrientation
                        & (Qt.PortraitOrientation | Qt.InvertedPortraitOrientation)

            width: isPortrait ? cameraLayer.width : cameraLayer.height
            height: isPortrait ? cameraLayer.height : cameraLayer.width

            anchors.centerIn: parent

            opacity: 0
            rotation: QtQuick.Screen.angleBetween(Lipstick.compositor.sensorOrientation, QtQuick.Screen.primaryOrientation)

            states: State {
                name: "launching"
                when: startupWatcher.running
                PropertyChanges {
                    target: splash
                    opacity: 1
                }
            }
            transitions: [
                Transition {
                    from: "launching"
                    SequentialAnimation {
                        PauseAnimation {
                            duration: 500
                        }
                    }
                    FadeAnimation {}
                }
            ]
        }
    }

    LauncherItem {
        id: cameraLauncher

        filePath: "/usr/share/applications/jolla-camera-lockscreen.desktop"
    }

    StartupWatcher {
        id: startupWatcher

        launcherItem: cameraLauncher
        onStartupFailed: {
            if (cameraLayer.active) {
                Lipstick.compositor.setCurrentWindow(Lipstick.compositor.obscuredWindow)
            }
        }
    }
}
