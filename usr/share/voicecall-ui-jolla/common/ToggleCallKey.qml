import QtQuick 2.0
import org.nemomobile.policy 1.0
import Sailfish.Media 1.0

Item {
    id: callKey
    signal pressed()

    Permissions {
        id: permissions
        enabled: telephony.active
        applicationClass: "call"

        Resource {
            required: true
            type: Resource.HeadsetButtons
        }
    }

    MediaKey {
        enabled: permissions.acquired
        key: Qt.Key_ToggleCallHangup
        onPressed: callKey.pressed()
    }

    MediaKey {
        enabled: permissions.acquired
        key: Qt.Key_MediaTogglePlayPause
        onPressed: callKey.pressed()
    }
}
