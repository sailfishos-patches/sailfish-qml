import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Settings.Networking.Vpn 1.0
import Sailfish.Settings.Networking 1.0

Column {
    property string defaultText

    function setProperties(providerProperties) {
        var getProperty = function(name) {
            if (providerProperties) {
                return providerProperties[name] || ''
            }
            return ''
        }

        pptpUser.text = getProperty('PPTP.User')

        pppdOptions.setProperties(providerProperties)
    }

    function updateProperties(providerProperties) {
        var updateProvider = function(name, value) {
            // If the value is empty/default, do not include the property in the configuration
            if (value != '' && value != '_default') {
                providerProperties[name] = value
            }
        }

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
