
import QtQuick 2.0
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.configuration 1.0
import org.nemomobile.dbus 2.0
import Sailfish.Silica.private 1.0 as SilicaPrivate
import "../main"
import "../compositor"

ApplicationWindow {
    id: launcherWindow

    cover: undefined

//    enabled: !Lipstick.compositor.deviceIsLocked

    allowedOrientations: Lipstick.compositor.topmostWindowOrientation

    ConfigurationGroup {
        id: launcherViewSettings
        path: "/apps/lipstick-jolla-home-qt5/launcherView"
        property bool glassBackground: true
        property bool themedBackgroundColor: true
        property real backgroundOpacity: 0.9
    }

    children: Item {
        z: -1
        anchors.fill: parent
        opacity: launcherViewSettings.backgroundOpacity
        onOpacityChanged: console.log(opacity)
        Component.onCompleted: console.log(opacity, launcherViewSettings.glassBackground)

        SilicaPrivate.Wallpaper {
            anchors.centerIn: parent
            visible: launcherViewSettings.glassBackground
            width: parent.width
            height: parent.height
            source: Theme.backgroundImage
            windowRotation: 360 - pageStack.currentPage.rotation
        }

        Rectangle {
            anchors.fill: parent
            visible: !launcherViewSettings.glassBackground
            color: launcherViewSettings.themedBackgroundColor ? Theme.highlightDimmerColor : "black"
            Component.onCompleted: console.log(color)
        }
    }

    property Item remorse
    property bool removeApplicationEnabled

    function removeApplication(desktopFile, title) {
        if (!remorse) {
            remorse = remorseComponent.createObject(pageStack.currentPage)
        } else if (remorse.desktopFile !== "" && remorse.desktopFile !== desktopFile) {
            remorse.removePackageByDesktopFile()
            remorse.cancel()
        }
        remorse.desktopFile = desktopFile

        //: Notification indicating that an application will be removed, %1 will be replaced by application name
        //% "Uninstalling %1"
        remorse.execute(qsTrId("lipstick-jolla-home-no-uninstalling").arg(title))
    }

    Component {
        id: remorseComponent

        RemorsePopup {
            property string desktopFile

            function removePackageByDesktopFile() {
                if (desktopFile !== "") {
                    installationHandler.call("removePackageByDesktopFile", desktopFile)
                    desktopFile = ""
                }
            }

            z: 100
            onTriggered: removePackageByDesktopFile()
            onCanceled: desktopFile = ""

            DBusInterface {
                id: installationHandler
                service: "org.sailfishos.installationhandler"
                path: "/org/sailfishos/installationhandler"
                iface: "org.sailfishos.installationhandler"
            }
        }
    }

    initialPage: Component { Page {
        id: page

        allowedOrientations: Lipstick.compositor.topmostWindowOrientation
        layer.enabled: orientationTransitionRunning

        Launcher {
            // We don't want the pager to resize due to keyboard being shown.
            height: page.height
            width: parent.width
        }

        orientationTransitions: OrientationTransition {
            page: page
            applicationWindow: launcherWindow
        }
    } }
}
