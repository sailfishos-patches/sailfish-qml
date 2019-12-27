import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import Nemo.Configuration 1.0
import Sailfish.Policy 1.0

Column {
    id: root

    property var networkManager
    property bool canResetCounter
    property bool simPresent
    property string subscriberIdentity

    property double homeSent
    property double homeReceived
    property double roamingSent
    property double roamingReceived
    property alias resetTime: cellularResetTime.value
    property alias lastResetTime: roamingCounter.lastResetTime

    signal resetCounter(var services)

    width: parent.width
    spacing: Theme.paddingLarge

    CounterDelegate {
        //% "Home network"
        title: qsTrId("settings_network-la-home_network")
        sent: root.homeSent
        received: root.homeReceived
    }
    CounterDelegate {
        id: roamingCounter
        //% "Roaming"
        title: qsTrId("settings_network-la-roaming")
        sent: root.roamingSent
        received: root.roamingReceived
    }

    ConfigurationValue {
        id: cellularResetTime

        key: {
            // Currently only the first cellular service is used.
            var services = networkManager.cellularServices
            for (var i = 0; i < services.length; ++i) {
                var serviceParts = services[i].split("_")
                if (serviceParts.length !== 3 || serviceParts[0] !== "/net/connman/service/cellular")
                    continue

                if (subscriberIdentity !== serviceParts[1])
                    continue

                var index = services[i].lastIndexOf("/")
                if (index === -1)
                    continue

                var s = services[i].substr(index + 1)
                return "/apps/jolla-settings/cellular_counter_reset_time/" + s
            }

            return "/apps/jolla-settings/cellular_counter_reset_time"
        }
    }

    Column {
        width: parent.width
        spacing: Theme.paddingMedium

        Button {
            //% "Clear"
            text: qsTrId("settings_network-bt-clear")
            enabled: !networkManager.cellularServicesGenerated && simPresent
                     && root.canResetCounter
                     && AccessPolicy.networkDataCounterSettingsEnabled
            anchors.horizontalCenter: parent.horizontalCenter

            onClicked: {
                if (subscriberIdentity === "")
                    return

                var services = networkManager.instance.servicesList("cellular")
                var resetServices = []
                for (var i = 0; i < services.length; ++i) {
                    var serviceParts = services[i].split("_")
                    if (serviceParts.length !== 3 || serviceParts[0] !== "/net/connman/service/cellular")
                        continue

                    if (subscriberIdentity !== serviceParts[1])
                        continue

                    resetServices.push(services[i])
                }

                root.resetCounter(resetServices)
            }
        }

        Label {
            width: parent.width
            visible: !AccessPolicy.networkDataCounterSettingsEnabled
            //: %1 is an operating system name without the OS suffix
            //% "Clearing of data counters disabled by %1 Device Manager"
            text: qsTrId("settings_network-la-mobile_data_clear_mdm_disabled")
                .arg(aboutSettings.baseOperatingSystemName)
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeTiny
            wrapMode: Text.Wrap
        }
    }

    AboutSettings {
        id: aboutSettings
    }
}
