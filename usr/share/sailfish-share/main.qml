/****************************************************************************************
** Copyright (c) 2021 Open Mobile Platform LLC.
** Copyright (c) 2023 Jolla Ltd.
**
** All rights reserved.
**
** This file is part of Sailfish Transfer Engine component package.
**
** You may use this file under the terms of BSD license as follows:
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**
** 1. Redistributions of source code must retain the above copyright notice, this
**    list of conditions and the following disclaimer.
**
** 2. Redistributions in binary form must reproduce the above copyright notice,
**    this list of conditions and the following disclaimer in the documentation
**    and/or other materials provided with the distribution.
**
** 3. Neither the name of the copyright holder nor the names of its
**    contributors may be used to endorse or promote products derived from
**    this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
** AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
** FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
** DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
** SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
** CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
** OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
