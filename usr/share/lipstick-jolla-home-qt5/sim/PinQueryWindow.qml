/****************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1
import com.jolla.settings.system 1.0
import MeeGo.QOfono 0.2
import "../sim"
import "../main"

SimPinBackground {
    id: root

    property string modemPath
    property SimPinWrapper _currentItem
    readonly property bool _needsPin: ofonoSimManager.simPresent &&
                                      (ofonoSimManager.pinRequired === OfonoSimManager.SimPin ||
                                       ofonoSimManager.pinRequired === OfonoSimManager.SimPuk)
    property bool emergency

    signal pinConfirmed
    signal skipped

    function reset() {
        replace(pinQueryComponent)
    }

    function replace(wrapperItem) {
        if (_currentItem) {
            _currentItem.destroyWhenHidden = true
            _currentItem.opacity = 0.0
        }

        _currentItem = wrapperItem.createObject(root)
        _currentItem.opacity = 1.0
        _currentItem.focus = true
        opacity = 1.0
        return _currentItem
    }

    function _waitForPinResult() {
        // wait until the pinRequired changes, else this window disappears immediately and
        // the app that brought up this UI may still be in the old "pin required" state
        var wrapperItem = replace(waitForPinActivationComponent)
        wrapperItem.fadeOut()
    }

    function _cleanUp() {
        if (_currentItem) {
            _currentItem.destroyWhenHidden = true
        }
    }

    onSkipped: _cleanUp()
    onPinConfirmed: {
        _cleanUp()
        opacity = 0.0
    }

    Behavior on opacity { FadeAnimation {} }

    Component {
        id: waitForPinActivationComponent
        SimPinWrapper {
            id: waitForPinActivation
            objectName: "waitForPinActivation"
            function fadeOut() {
                if (!root._needsPin) {
                    root.pinConfirmed()
                } else {
                    busyIndicator.running = true
                    ofonoSimManager.pinRequiredChanged.connect(_checkPinRequired)
                    maxWaitTimer.start()
                }
            }

            function _finish() {
                busyIndicator.running = false
                ofonoSimManager.pinRequiredChanged.disconnect(_checkPinRequired)
                root.pinConfirmed()
            }

            function _checkPinRequired() {
                if (!root._needsPin) {
                    maxWaitTimer.stop()
                    _finish()
                }
            }

            Timer {
                id: maxWaitTimer
                interval: 1000

                onTriggered: waitForPinActivation._finish()
            }

            PageBusyIndicator {
                id: busyIndicator
            }
        }
    }

    OfonoSimManager {
        id: ofonoSimManager
        modemPath: root.modemPath
        readonly property bool simPresent: valid && present
        onSimPresentChanged: if (root.visible && valid && !present) root.skipped()
    }

    Component {
        id: pinQueryComponent
        SimPinWrapper {
            objectName: "pinQuery"
            SimPinQuery {
                id: pinQuery

                modemPath: root.modemPath
                showCancelButton: true
                showBackgroundGradient: false
                multiSimManager: Desktop.simManager

                onDone: {
                    if (!PinQueryAgent.simPinRequired) {
                        clear()
                        root._waitForPinResult()
                    }
                }
                onPinEntryCanceled: {
                    clear()
                    root.replace(pinQuerySkippedComponent)
                }
                onSimPermanentlyLocked: {
                    clear()
                    root.replace(pinLockedNoticeComponent)
                }
                Binding {
                    target: root
                    property: "emergency"
                    value: pinQuery.emergency
                }
            }
        }
    }

    Component {
        id: pinQuerySkippedComponent
        SimPinWrapper {
            objectName: "pinQuerySkipped"
            SimPinQuerySkippedNotice {
                enabled: opacity === 1.0
                visible: parent.visible
                opacity: parent.opacity

                onContinueClicked: root.skipped()
            }
        }
    }

    Component {
        id: pinLockedNoticeComponent
        SimPinWrapper {
            objectName: "pinQuerySimLocked"
            SimLockedNotice {
                enabled: opacity === 1.0
                visible: parent.visible
                opacity: parent.opacity

                onContinueClicked: root.skipped()
            }
        }
    }

    Component.onCompleted: root.reset()
}
