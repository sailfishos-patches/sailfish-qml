/****************************************************************************************
**
** Copyright (c) 2021 Open Mobile Platform LLC.
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/
import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

ApplicationWindow {
    id: root

    property var _shareDialog

    function _open(shareActionConfiguration) {
        if (_shareDialog) {
            _shareDialog.lower()
            _shareDialog.destroy()
        }
        _shareDialog = shareDialogComponent.createObject(
                    root, { "shareActionConfiguration": shareActionConfiguration })
    }

    initialPage: Component {
        Page {
            allowedOrientations: Orientation.All
        }
    }
    allowedOrientations: Orientation.All
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    Component {
        id: shareDialogComponent

        ShareSystemDialog {
            Component.onCompleted: {
                if (!autoDestroy.running) {
                    activate()
                }
            }

            onClosed: {
                autoDestroy.start()
            }
        }
    }

    DBusInterface {
        bus: DBus.SystemBus
        service: 'com.nokia.mce'
        path: '/com/nokia/mce/signal'
        iface: 'com.nokia.mce.signal'
        signalsEnabled: true

        function display_status_ind(state) {
            if (state !== "on" && !!_shareDialog) {
                _shareDialog.dismiss()
                autoDestroy.start()
            }
        }
    }

    Timer {
        id: autoDestroy

        // Wait a good amount of time before auto-exiting. Otherwise, if sharing triggers launching
        // of an app via dbus, and sailfish-share quits before the app is launched, dbus will abort
        // launching of that app.
        interval: 30*1000

        onTriggered: {
            console.warn("sailfish-share: exiting...")
            Qt.quit()
        }
    }

    DBusAdaptor {
        id: dbusAdaptor

        service: "org.sailfishos.share"
        path: "/"
        iface: "org.sailfishos.share"

        function share(shareActionConfiguration) {
            autoDestroy.stop()
            root._open(shareActionConfiguration)
        }
    }
}
