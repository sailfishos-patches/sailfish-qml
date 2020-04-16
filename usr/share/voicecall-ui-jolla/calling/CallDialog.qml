import QtQuick 2.1
import QtQuick.Window 2.1
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0

SystemDialogWindow {
    id: callDialog
    title: "Call"
    category: SystemDialogWindow.Call

    property bool dialogShown
    property bool hidden: !active && (visibility == Window.Hidden || visibility == Window.Minimized)
    property bool activated
    property bool _windowVisibleOnActivate
    property bool _restoreApplication
    property alias callDialogApplicationWindow: __silica_applicationwindow_instance

    onHiddenChanged: {
        if (dialogShown && hidden && main.state === "incoming") {
            telephony.silenceIncomingCall()
        }
        if (hidden) {
            dialogShown = false
        }
    }
    property bool shown: active && visibility != Window.Hidden && visibility != Window.Minimized
    onShownChanged: {
        dialogShown = true
    }

    function activate() {
        _windowVisibleOnActivate = __window.visible
        activated = true
        showFullScreen()
        raise()
    }

    function deactivate() {
        activated = false
        lower()
    }

    onClosing: {
        if (activated) {
            close.accepted = false
        }
    }

    onActivatedChanged: _restoreApplication = false

    onVisibilityChanged: {
        if (activated && visibility == Window.Hidden) {
            _restoreApplication = _windowVisibleOnActivate
        } else if (visibility == Window.FullScreen && _restoreApplication) {
            __window.raise()
        }
    }

    // Disable gestures during emergency call
    flags: Qt.Window | (telephony.isEmergency ? Qt.WindowOverridesSystemGestures : 0)

    ApplicationWindow {
        // ApplicationWindow isn't really designed for multiple instantiations.
        id: __silica_applicationwindow_instance

        allowedOrientations: main.allowedOrientations
        _defaultPageOrientations: main._defaultPageOrientations
        _defaultLabelFormat: Text.PlainText
        _persistentOpenGLContext: true
        _persistentSceneGraph: true
        cover: undefined
        initialPage: Component {
            CallingView {
                onCompleteAnimation: main.hangupAnimation.complete()
                onSetAudioRecording: main.setAudioRecording(recording)
            }
        }
    }
}
