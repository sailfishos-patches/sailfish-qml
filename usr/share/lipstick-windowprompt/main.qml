/*
 * Copyright (c) 2017 - 2021 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import QtQuick.Window 2.0
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1

ApplicationWindow {
    id: root

    property var _promptWindow
    property var _showTimer
    property string _componentName

    function singleShot(timeout, callback) {
        var timer = Qt.createQmlObject("import QtQuick 2.6; Timer {}", root, "singleShot")
        timer.interval = timeout
        timer.repeat = false
        timer.triggered.connect(callback)
        timer.start()
        return timer
    }

    function _showPrompt(promptConfig) {
        var delay = false
        if (_promptWindow) {
            _promptWindow.lower()
            delay = true
        }
        if (!_promptWindow || _componentName != promptConfig.componentName) {
            _componentName = promptConfig.componentName
            var comp = Qt.createComponent(Qt.resolvedUrl(_componentName))
            if (comp.status == Component.Error) {
                console.log(promptConfig.componentName, "error:", comp.errorString())
                return
            }
            _promptWindow = comp.createObject(root)
            _promptWindow.done.connect(_promptDone)
        }
        if (delay) {
            var config = promptConfig
            _showTimer = singleShot(400, function() {
                _promptWindow.init(config)
                _showTimer = undefined
            })
        } else {
            _promptWindow.init(promptConfig)
        }
    }

    function _promptDone(window, unregister) {
        if (unregister)
            manager.unregisterTerms(window.promptConfig)
        window.lower()
        var config = window.promptConfig
        singleShot(400, function() {
            manager.finish(config)
        })
    }

    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText
    cover: undefined

    WindowPromptManager {
        id: manager

        onCreateTermsPrompt: {
            // Register the terms/agreement so that lipstick knows to re-display the dialog on
            // startup hasn't yet been accepted (e.g. if rebooted without accepting it).

            if (!promptConfig.componentName) {
                promptConfig.componentName = "TermsPromptWindow.qml"
            }

            if (manager.registerTerms(promptConfig)) {
                manager.queue(id, promptConfig)
            } else {
                console.log("showTermsPrompt() failed, cannot register config", termsId(promptConfig))
                manager.discard(id)
            }
        }

        onCreateStorageDevicePrompt: {
            if (!promptConfig.componentName) {
                promptConfig.componentName = "StorageDeviceSystemDialog.qml"
            }

            manager.queue(id, promptConfig)
        }

        onCreateInfoWindow: {
            if (!promptConfig.componentName) {
                promptConfig.componentName = "InfoWindow.qml"
            }

            manager.queue(id, promptConfig)
        }

        onCreatePermissionPrompt: {
            if (!promptConfig.componentName) {
                promptConfig.componentName = "PermissionPrompt.qml"
            }

            manager.queue(id, promptConfig)
        }

        onShowPromptUi: {
            _showPrompt(promptConfig)
        }

        onHidePromptUi: {
            if (_showTimer) {
                _showTimer.stop()
                _showTimer = undefined
            }
            if (_promptWindow) {
                _promptWindow.lower()
            }
        }
    }
}
