/*
 * Copyright (c) 2024 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import QtQuick.Window 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Nemo.DBus 2.0

ApplicationWindow {
    id: root

    property PermissionQueryWindow _permissionQueryWindow
    property string uuid
    property int queryCount
    property int queryIndex
    property bool replied

    Component.onCompleted: {
        delayedQuit.restart()
    }

    function _showConsentWindow(uuid, buttons, groupName, message, detailedMessage, buttonTexts) {
        root.replied = false
        if (!_permissionQueryWindow) {
            var comp = Qt.createComponent(Qt.resolvedUrl("PermissionQueryWindow.qml"))
            if (comp.status == Component.Error) {
                console.log("PermissionQueryWindow.qml error:", comp.errorString())
                return
            }
            _permissionQueryWindow = comp.createObject(root)
            _permissionQueryWindow.done.connect(function(uuid, result) {
                if (!root.replied) {
                    dbusClient.reply(uuid, result)
                    root.replied = true
                }
                if (result == _permissionQueryWindow.replyCanceled || root.queryIndex >= root.queryCount - 1) {
                    root._closeWindow()
                    delayedQuit.restart()
                }
            })
        }
        _permissionQueryWindow.init(uuid, buttons, groupName, message, detailedMessage, buttonTexts)
    }

    function _closeWindow() {
        if (_permissionQueryWindow
                && _permissionQueryWindow.visibility != Window.Hidden) {
            _permissionQueryWindow.lower()
        }
    }

    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText
    cover: undefined

    Timer {
        id: delayedQuit
        interval: 10000
        onTriggered: {
            console.log("lipstick-appsupport-ui: exiting...")
            Qt.quit()
        }
    }

    DBusInterface {
        id: dbusClient
        bus: DBus.SessionBus

        service: 'com.jolla.appsupport.permissions'
        path: '/com/jolla/appsupport/permissions'
        iface: 'com.jolla.appsupport.permissions'

        function reply(key, result) {
            call('consentReply', [ key, result ])
        }
    }

    DBusAdaptor {
        id: dbusService

        service: 'com.jolla.appsupport.consent'
        iface: 'com.jolla.appsupport.consent'
        path: '/com/jolla/appsupport/consent'

        xml:    '  <interface name="com.jolla.appsupport.consent">\n' +
                '    <method name="checkConsent">\n' +
                '      <arg name="uuid" type="s" direction="in"/>' +
                '      <arg name="count" type="i" direction="in"/>' +
                '      <arg name="index" type="i" direction="in"/>' +
                '      <arg name="buttons" type="i" direction="in"/>' +
                '      <arg name="groupName" type="s" direction="in"/>' +
                '      <arg name="packageName" type="s" direction="in"/>' +
                '      <arg name="appName" type="s" direction="in"/>' +
                '      <arg name="message" type="s" direction="in"/>' +
                '      <arg name="detailedMessage" type="s" direction="in"/>' +
                '      <arg name="buttonTexts" type="as" direction="in"/>' +
                '      <arg name="status" type="i" direction="out"/>' +
                '    </method>\n' +
                '    <method name="cancel">\n' +
                '    </method>\n' +
                '    <method name="watchdog">\n' +
                '      <arg name="uuid" type="s" direction="out"/>' +
                '    </method>\n' +
                '  </interface>\n'

        function checkConsent(uuid,
                              count,
                              index,
                              buttons,
                              groupName,
                              packageName,
                              appName,
                              message,
                              detailedMessage,
                              buttonTexts) {
            delayedQuit.restart()
            root.uuid = uuid
            root.queryCount = count
            root.queryIndex = index
            root._showConsentWindow(uuid, buttons, groupName, message, detailedMessage, buttonTexts)
            return 0
        }

        function cancel() {
            root._closeWindow()
            delayedQuit.restart()
        }

        function watchdog() {
            delayedQuit.restart()
            return root.uuid
        }
    }
}
