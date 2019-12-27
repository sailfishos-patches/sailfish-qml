import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import Nemo.Connectivity 1.0
import Sailfish.Settings.Networking 1.0
import com.jolla.settings 1.0

IconTextSwitch {
    id: root

    property alias modemPath: mobileData.modemPath

    /*
     * connman service list updates after a delay after toggling Roaming Data allowed,
     * so prevent toggling during that small moment after user disables Data roaming
     * and when there is no connman service to connect.
     */
    property bool _clickAllowed: mobileData.valid
             && (!mobileData.roaming || mobileData.roamingAllowed)

    // Handle case where user tries to enable mobile data,
    // but no SIM card has been specified yet
    property bool dataSimRequested
    signal requestDataSim

    property bool expectedState
    busy: mobileData.status === MobileDataConnection.Connecting || (tapTimer.running && expectedState !== mobileData.autoConnect)
    automaticCheck: false
    enabled: mobileData.valid
    checked: enabled && mobileData.autoConnect
    icon.source: "image://theme/icon-m-data-traffic"

    function updateDefaultDataSim() {
        mobileData.defaultDataSim = Telephony.multiSimSupported ? mobileData.subscriberIdentity : "auto"
    }

    function requestConnect() {
        if (!busy && _clickAllowed) {
            mobileData.connect()
        }
    }

    text: mobileData.connectionName
          ? mobileData.connectionName
            //: Button that controls whether the mobile data internet connection is active
            //% "Internet"
          : qsTrId("settings_network-bt-mobile_internet")

    description: {
        if (mobileData.status === MobileDataConnection.Online) {
            //% "Connected"
            return qsTrId("settings_network-me-packetdata_connected")
        } else if (mobileData.status === MobileDataConnection.Limited) {
            //% "Limited connectivity"
            return qsTrId("settings_network-me-packetdata_limited")
        } else if (mobileData.status === MobileDataConnection.Connecting) {
            //% "Connecting"
            return qsTrId("settings_network-me-packetdata_connecting")
        } else if (mobileData.autoConnect) {
            //% "Enabled"
            return qsTrId("settings_network-me-packetdata_enabled")
        } else {
            //% "Off"
            return qsTrId("settings_network-me-packetdata_off")
        }
    }

    onClicked: {
        // Set default data sim before checking _clickAllowed as click allowed is guarded with MobileDataConnection valid.
        updateDefaultDataSim()

        if (Telephony.multiSimSupported && mobileData.subscriberIdentity.length === 0) {
            // No valid data SIM defined, prompt user to select data SIM
            requestDataSim()
        } else if (!busy && _clickAllowed) {
            expectedState = !mobileData.autoConnect
            mobileData.autoConnect = expectedState
            if (!expectedState) {
                mobileData.disconnect()
            }
            tapTimer.start()
        }
    }

    Timer {
        id: tapTimer
        interval: 2000
    }

    NetworkingMobileDataConnection {
        id: mobileData
        objectName: "MobileDataSwitch_MobileDataConnection"
    }
}
