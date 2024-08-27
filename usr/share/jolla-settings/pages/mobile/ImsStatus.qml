import QtQuick 2.0
import Sailfish.Silica 1.0
import QOfono 0.2
import Sailfish.Settings.Networking 1.0

Column {
    property alias path: ims.modemPath

    TextSwitch {
        automaticCheck: false
        checked: ims.registration > OfonoIpMultimediaSystem.RegistrationDisabled

        //: Text switch that controls whether the 4G voice calls are possible
        //% "4G calling (VoLTE)"
        text: qsTrId("settings_network-bt-4g_voicecall")

        //% "Registered"
        description: ims.registered ? qsTrId("settings_network-bt-4g_voicecall_registered")
                               //% "Not registered"
                             : qsTrId("settings_network-bt-4g_voicecall_not_registered")

        busy: ims.registration === OfonoIpMultimediaSystem.RegistrationAuto && !ims.registered

        onClicked: {
            if (ims.registration === OfonoIpMultimediaSystem.RegistrationDisabled) {
                ims.registration = OfonoIpMultimediaSystem.RegistrationAuto
            } else {
                ims.registration = OfonoIpMultimediaSystem.RegistrationDisabled
            }
        }
    }

    Label {
        x: Theme.horizontalPageMargin + Theme.itemSizeExtraSmall - Theme.paddingLarge
        width: parent.width - x - Theme.horizontalPageMargin
        height: implicitHeight + Theme.paddingMedium
        wrapMode: Text.Wrap
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.highlightColor
        //% "4G calls may be required by your operator. They also "
        //% "provide better call quality and better experience during active mobile data transfers."
        text: qsTrId("settings_network-la-4g_voicecall_description")
    }

    OfonoIpMultimediaSystem {
        id: ims
    }
}
