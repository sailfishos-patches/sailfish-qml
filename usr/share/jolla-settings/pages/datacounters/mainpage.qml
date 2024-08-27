import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import Sailfish.Policy 1.0
import Connman 0.2
import com.jolla.settings.system 1.0
import Nemo.Configuration 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.AccessControl 1.0

Page {
    id: mainPage

    property Item remorse
    property string resetType
    property date pendingResetTime
    property var resetCellularServices
    property bool pageReady: sailfishSimManager.ready || status == PageStatus.Active
    readonly property bool phoneUser: AccessControl.hasGroup(AccessControl.RealUid, "sailfish-phone")
    onPageReadyChanged: if (pageReady) pageReady = true // remove binding

    function clearCounter() {
        if (!remorse)
            remorse = remorseComponent.createObject(mainPage)
        if (resetType === "cellular") {
            //% "Cleared mobile data counters"
            remorse.execute(qsTrId("settings_network-me-cleared_mobile_data_counters"))
        } else if (resetType === "wifi") {
            //% "Cleared WLAN counters"
            remorse.execute(qsTrId("settings_network-me-cleared_wlan_counters"))
        }
    }

    AboutSettings {
        id: aboutSettings
    }

    SimManager {
        id: sailfishSimManager
    }

    Component {
        id: remorseComponent
        RemorsePopup {
            onCanceled: {
                resetType = ""
                resetCellularServices = []
            }
            onTriggered: {
                if (resetType === "cellular") {
                    for (var i = 0; i < resetCellularServices.length; ++i) {
                        usageCounter.resetServiceCounter(resetCellularServices[i])
                    }
                } else if (resetType === "wifi") {
                    networkManager.instance.resetCountersForType(resetType)
                    usageCounter.wifiData = {}
                    wlanResetTime.value = pendingResetTime
                }

                resetType = ""
                resetCellularServices = []
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content

            enabled: !usageCounter.calculating && pageReady
            Behavior on opacity { FadeAnimator {} }
            opacity: enabled ? 1.0 : 0.0
            bottomPadding: Theme.paddingLarge

            width: parent.width

            PageHeader {
                //% "Data counters"
                title: qsTrId("settings_network-he-data_counters")
            }

            Repeater {
                id: mobileDataRepeater

                model: sailfishSimManager.availableModems

                delegate: Column {
                    property alias ofonoSimManager: simPlaceholder.simManager
                    property string subscriberIdentity: ofonoSimManager.present
                                                        ? ofonoSimManager.subscriberIdentity
                                                        : (lastCellularSubscriberIdentity.value != undefined
                                                           ? lastCellularSubscriberIdentity.value
                                                           : "")

                    width: parent.width

                    ConfigurationValue {
                        id: lastCellularSubscriberIdentity

                        key: "/apps/jolla-settings/last_cellular_subscriberidentities" + modelData
                    }

                    SectionHeader {
                        visible: mainPage.phoneUser
                        text: mobileDataRepeater.count == 1
                                //% "Mobile data"
                              ? qsTrId("settings_network-he-mobile_data")
                              : sailfishSimManager.simNames[index]
                    }

                    SimSectionPlaceholder {
                        id: simPlaceholder
                        visible: mainPage.phoneUser
                        modemPath: modelData
                        multiSimManager: sailfishSimManager
                    }

                    Loader {
                        x: Theme.horizontalPageMargin
                        width: parent.width - Theme.horizontalPageMargin*2
                        height: item ? item.implicitHeight + Theme.paddingLarge : 0
                        clip: true
                        Behavior on height { enabled: pageReady; NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

                        sourceComponent: MobileDataCounterGroup {
                            networkManager: mainPage.networkManager
                            canResetCounter: !usageCounter.calculating && !(remorse && remorse.active)

                            homeSent: resetType !== "cellular" && usageCounter.cellularHomeSent[subscriberIdentity]
                                      ? usageCounter.cellularHomeSent[subscriberIdentity]
                                      : 0
                            homeReceived: resetType !== "cellular" && usageCounter.cellularHomeReceived[subscriberIdentity]
                                          ? usageCounter.cellularHomeReceived[subscriberIdentity]
                                          : 0
                            roamingSent: resetType !== "cellular" && usageCounter.cellularRoamingSent[subscriberIdentity]
                                         ? usageCounter.cellularRoamingSent[subscriberIdentity]
                                         : 0
                            roamingReceived: resetType !== "cellular" && usageCounter.cellularRoamingReceived[subscriberIdentity]
                                             ? usageCounter.cellularRoamingReceived[subscriberIdentity]
                                             : 0
                            lastResetTime: resetType == "cellular" ? pendingResetTime : resetTime
                            onResetCounter: {
                                resetCellularServices = services
                                resetType = "cellular"
                                pendingResetTime = new Date
                                clearCounter()
                            }
                        }

                        active: !simPlaceholder.enabled && mainPage.phoneUser
                        opacity: 1 - simPlaceholder.opacity
                        onLoaded: {
                            item.simPresent = Qt.binding(function() { return ofonoSimManager.present })
                            item.subscriberIdentity = Qt.binding(function() { return subscriberIdentity })
                        }
                    }
                }
            }

            SectionHeader {
                //% "WLAN"
                text: qsTrId("settings_network-he-wlan")
            }

            CounterDelegate {
                x: Theme.horizontalPageMargin
                width: parent.width - Theme.horizontalPageMargin*2

                lastResetTime: resetType == "wifi" ? pendingResetTime : wlanResetTime.value
                sent: resetType == "wifi" ? 0 : usageCounter.wlanSent
                received: resetType == "wifi" ? 0 : usageCounter.wlanReceived
            }

            Column {
                width: parent.width
                topPadding: Theme.paddingLarge
                bottomPadding: resetWlanDisabledLabel.visible ? Theme.paddingLarge : 0
                spacing: Theme.paddingMedium

                Button {
                    //% "Clear"
                    text: qsTrId("settings_network-bt-clear")
                    anchors.horizontalCenter: parent.horizontalCenter
                    enabled: !usageCounter.calculating && !(remorse && remorse.active)
                             && AccessPolicy.networkDataCounterSettingsEnabled
                    onClicked: {
                        resetType = "wifi"
                        pendingResetTime = new Date
                        clearCounter()
                    }
                }

                Label {
                    id: resetWlanDisabledLabel
                    x: Theme.horizontalPageMargin
                    width: parent.width - Theme.horizontalPageMargin*2
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
        }
    }

    BusyLabel {
        //% "Calculating"
        text: qsTrId("settings_network-he-calculating")
        running: usageCounter.calculating && pageReady
    }

    NetworkCounter {
        id: usageCounter

        property bool _disabled

        accuracy: 1024
        interval: 60
        running: Qt.application.active && !_disabled

        function restart() {
            // Toggle off then on again
            _disabled = true
            _disabled = false
        }

        // filter out the services we're not watching here.
        function filterUnneededUsage(serviceList) {
            var filtered = []
            for (var i = 0; i < serviceList.length; ++i) {
                var service = serviceList[i]
                if (service.indexOf("/net/connman/service/wifi_") == 0
                        || service.indexOf("/net/connman/service/cellular_") == 0) {
                    filtered.push(service)
                }
            }
            return filtered
        }

        property bool calculating: pendingUsage.length > 0
        property var pendingUsage: filterUnneededUsage(networkManager.instance.savedServicesList())

        property var cellularHomeSent: sumOfSubscriber(homeMobileData, "TX.Bytes")
        property var cellularHomeReceived: sumOfSubscriber(homeMobileData, "RX.Bytes")
        property var cellularRoamingSent: sumOfSubscriber(roamingMobileData, "TX.Bytes")
        property var cellularRoamingReceived: sumOfSubscriber(roamingMobileData, "RX.Bytes")
        property double wlanSent: sumOf(wifiData, "TX.Bytes")
        property double wlanReceived: sumOf(wifiData, "RX.Bytes")

        property var wifiData: ({})
        property var homeMobileData: ({})
        property var roamingMobileData: ({})

        onCounterChanged: {
            if (pendingUsage.length > 0) {
                var services = pendingUsage
                for (var i = 0; i < services.length; ++i) {
                    if (services[i] === servicePath) {
                        services.splice(i, 1)
                        break
                    }
                }
                pendingUsage = services
            }

            if (!roaming && servicePath.indexOf("/net/connman/service/wifi_") === 0) {
                // wifi service
                wifiData = updateData(servicePath, wifiData, counters)
            } else if (servicePath.indexOf("/net/connman/service/cellular_") === 0) {
                // cellular service
                if (roaming)
                    roamingMobileData = updateData(servicePath, roamingMobileData, counters)
                else
                    homeMobileData = updateData(servicePath, homeMobileData, counters)
            }

            if (!pendingUsage.length)
                networkManager.updateCellularServices()
        }

        function resetServiceCounter(servicePath) {
            networkService.path = servicePath
            networkService.resetCounters()

            if (homeMobileData.hasOwnProperty(servicePath)) {
                var hmd = homeMobileData
                hmd[servicePath] = {}
                homeMobileData = hmd
            }

            if (roamingMobileData.hasOwnProperty(servicePath)) {
                var rmd = roamingMobileData
                rmd[servicePath] = {}
                roamingMobileData = rmd
            }

            var index = servicePath.lastIndexOf("/")
            if (index >= 0)
                cellularResetTimes.setValue(servicePath.substr(index + 1), pendingResetTime)
        }

        function updateData(service, oldData, changedData) {
            var data
            if (oldData.hasOwnProperty(service))
                data = oldData[service]
            else
                data = {}

            for (var p in changedData)
                data[p] = changedData[p]

            oldData[service] = data
            return oldData
        }

        // Calculate the sum of all 'prop' properties of items in the 'object' array.
        function sumOf(object, prop) {
            var sum = Number.NaN
            for (var s in object)
                sum = (isNaN(sum) ? 0 : sum) + object[s][prop]
            return sum
        }

        // Calculate the sum of all 'prop' properties of services for 'subscriber' items in the 'object' array.
        function sumOfSubscriber(object, prop) {
            var sums = {}
            for (var s in object) {
                var serviceParts = s.split("_")
                if (serviceParts.length !== 3 || serviceParts[0] !== "/net/connman/service/cellular")
                    continue

                var subscriberIdentity = serviceParts[1]
                if (sums.hasOwnProperty(subscriberIdentity))
                    sums[subscriberIdentity] = sums[subscriberIdentity] + object[s][prop]
                else
                    sums[subscriberIdentity] = object[s][prop]
            }

            return sums
        }
    }

    property var networkManager: NetworkManagerFactory {    // Define as property to avoid id that is same as the MobileDataCounterGroup property

        // Available cellular services, only data usage for these services will be reported
        property var cellularServices: []
        property var cellularServicesGenerated

        function updateCellularServices() {
            var newCellularServices = instance.servicesList("cellular")

            if (newCellularServices.length) {
                cellularServices = newCellularServices
                cellularServicesGenerated = false
            } else {
                // Find the last used SIM provider services/counters as no cellular-services are available through 
                // connman when the device is on flight/offline-mode or when roaming with mobile data 
                // set to "do not allow".
                if (!usageCounter.pendingUsage.length) {
                    for (var i in usageCounter.homeMobileData)
                        newCellularServices[newCellularServices.length] = i

                    cellularServices = newCellularServices
                    cellularServicesGenerated = true
                }
            }
        }

        instance.onServicesChanged: {
            updateCellularServices()

            // Test if counters need to be restarted because the services changed and usage stats
            // have not been received for all expected services yet.
            if (usageCounter.running && usageCounter.pendingUsage.length > 0) {
                var pendingServices = usageCounter.pendingUsage
                var services = instance.servicesList("")

                for (var i = 0; i < services.length; ++i) {
                    var index = pendingServices.indexOf(services[i])
                    if (index >= 0)
                        pendingServices.splice(index, 1)
                }

                if (pendingServices.length > 0) {
                    // Still waiting on usage stats for services but they are disappeared. Restart.
                    usageCounter.pendingUsage = filterUnneededUsage(instance.savedServicesList())
                    usageCounter.restart()
                }
            }
        }

        instance.onAvailableChanged: updateCellularServices()

        Component.onCompleted: updateCellularServices()
    }

    NetworkService {
        id: networkService
    }

    ConfigurationValue {
        id: wlanResetTime
        key: "/apps/jolla-settings/wlan_counter_reset_time"
    }

    ConfigurationGroup {
        id: cellularResetTimes

        path: "/apps/jolla-settings/cellular_counter_reset_time"
    }
}
