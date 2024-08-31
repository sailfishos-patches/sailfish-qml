/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

QtObject {
    property int selectionCount
    property var selectedApplications: []

    property var appsBeingInstalled: []

    function updateApplicationSelection(packageName, selected) {
        var index = selectedApplications.indexOf(packageName)
        if (selected && index < 0) {
            selectedApplications.push(packageName)
            selectionCount++
        } else if (!selected && index > -1) {
            selectedApplications.splice(index, 1)
            selectionCount--
        }
    }

    function installSelectedApps() {
        for (var i = 0; i < selectedApplications.length; i++) {
            if (appsBeingInstalled.indexOf(selectedApplications[i]) < 0) {
                appsBeingInstalled.push(selectedApplications[i])
                _storeClientInterface.call("installPackage", selectedApplications[i])
            }
        }
    }

    property DBusInterface _storeClientInterface: DBusInterface {
        service: "com.jolla.jollastore"
        path: "/StoreClient"
        iface: "com.jolla.jollastore"
    }
}
