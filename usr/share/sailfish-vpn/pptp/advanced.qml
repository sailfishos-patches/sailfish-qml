import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0

Column {
    property string defaultText

    function setProperties(providerProperties) {
        pptpUser.text = getProperty('PPTP.User')

        pppdOptions.setProperties(providerProperties)
    }

    function updateProperties(providerProperties) {
        updateProvider('PPTP.User', pptpUser.text)

        pppdOptions.updateProperties(providerProperties)
    }

    width: parent.width

    SectionHeader {
        //: Settings pertaining to the identification of the local user or device
        //% "Credentials"
        text: qsTrId("settings_network-he-vpn_pptp_credentials")
    }

    ConfigTextField {
        id: pptpUser

        //% "User name"
        label: qsTrId("settings_network-la-vpn_pptp_user")
    }

    PPPD {
        id: pppdOptions
    }
}
