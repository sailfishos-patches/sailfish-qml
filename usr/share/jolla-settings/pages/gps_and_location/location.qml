import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import com.jolla.settings 1.0
import org.freedesktop.contextkit 1.0
import Sailfish.Policy 1.0

Page {
    id: root

    function checkFlightMode() {
        // Until we have explicit UI to exit flight mode here, best just to do that when turning on gps or main location.
        if (locationSettings.gpsEnabled) {
            locationSettings.gpsFlightMode = false
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        PullDownMenu {
            id: pdm
            property bool hereAgreementCanBeRevoked: locationSettings.hereAvailable && locationSettings.hereState !== LocationConfiguration.OnlineAGpsAgreementNotAccepted
            property bool mlsAgreementCanBeRevoked: locationSettings.mlsAvailable && locationSettings.mlsOnlineState !== LocationConfiguration.OnlineAGpsAgreementNotAccepted
            visible: hereAgreementCanBeRevoked || mlsAgreementCanBeRevoked
            MenuItem {
                id: hereAgreement
                //% "Show HERE agreement"
                text: qsTrId("settings_location-me-show_here_agreement")
                onClicked: pageStack.animatorPush(agreementPageComponent, { providerName: "here" })
                visible: pdm.hereAgreementCanBeRevoked
            }
            MenuItem {
                id: mozillaAgreement
                //% "Show Mozilla agreement"
                text: qsTrId("settings_location-me-show_mls_agreement")
                onClicked: pageStack.animatorPush(agreementPageComponent, { providerName: "mls" })
                visible: pdm.mlsAgreementCanBeRevoked
            }
        }

        Column {
            id: content
            width: parent.width
            enabled: AccessPolicy.locationSettingsEnabled

            PageHeader {
                //% "Location"
                title: qsTrId("settings_location-he-location")
            }

            DisabledByMdmBanner {
                active: !content.enabled
            }

            ListItem {
                id: switchContainer

                contentHeight: locationSwitch.height
                openMenuOnPressAndHold: false

                TextSwitch {
                    id: locationSwitch
                    automaticCheck: false
                    checked: locationSettings.locationEnabled
                    enabled: AccessPolicy.locationSettingsEnabled

                    //% "Location"
                    text: qsTrId("settings_location-la-location")
                    //% "Allow applications to pinpoint your location. This feature consumes some battery power."
                    description: qsTrId("settings_location-la-location_switch_description")
                    highlighted: down || switchContainer.menuOpen

                    onClicked: {
                        var newState = !checked
                        locationSettings.locationEnabled = newState
                        root.checkFlightMode()
                    }
                }
            }

            SectionHeader {
                //: Title of the accuracy settings section
                //% "Accuracy"
                text: qsTrId("settings_location-la-simple_settings_section")
            }

            Column {
                id: simpleSettingsSection
                width: parent.width

                Timer {
                    // this timer exists to ensure that after pressing a switch,
                    // that switch is lit up even while the user may need to
                    // accept an agreement prior to being able to enable it.
                    id: transitionTimer
                    interval: 600 // long enough for page transition duration
                    property bool highAccuracyTransition
                    property bool batterySavingTransition
                    property bool deviceOnlyTransition
                    onTriggered: {
                        highAccuracyTransition = false
                        batterySavingTransition = false
                        deviceOnlyTransition = false
                    }
                }

                // note: assuming either online service installed
                property bool highAccuracySwitchChecked:  !transitionTimer.batterySavingTransition && !transitionTimer.deviceOnlyTransition &&
                                                          (transitionTimer.highAccuracyTransition ||
                                                                locationSettings.locationMode == LocationConfiguration.HighAccuracyMode)
                property bool batterySavingSwitchChecked: !transitionTimer.highAccuracyTransition && !transitionTimer.deviceOnlyTransition &&
                                                          (transitionTimer.batterySavingTransition ||
                                                                locationSettings.locationMode == LocationConfiguration.BatterySavingMode)
                property bool deviceOnlySwitchChecked:    !transitionTimer.highAccuracyTransition && !transitionTimer.batterySavingTransition &&
                                                          (transitionTimer.deviceOnlyTransition ||
                                                                locationSettings.locationMode == LocationConfiguration.DeviceOnlyMode)
                property bool customSwitchChecked: locationSettings.locationMode == LocationConfiguration.CustomMode

                TextSwitch {
                    id: highAccuracySwitch

                    automaticCheck: false
                    checked: simpleSettingsSection.highAccuracySwitchChecked
                    enabled: locationSettings.locationEnabled && AccessPolicy.locationSettingsEnabled

                    //% "High-accuracy positioning"
                    text: qsTrId("settings_location-la-high_accuracy_positioning")

                    //: Description of the high accuracy positioning mode
                    //% "Use online services to assist device GPS to calculate highly accurate positioning information. Data costs may apply."
                    description: qsTrId("settings_location-la-high_accuracy_positioning_description")

                    onClicked: {
                        if (locationSettings.locationMode == LocationConfiguration.CustomMode) {
                            locationSettings.saveCustomSettings()
                        }

                        transitionTimer.highAccuracyTransition = true
                        transitionTimer.start()
                        enableOnlineAgps(LocationConfiguration.HighAccuracyMode)
                        root.checkFlightMode()
                    }
                }
                TextSwitch {
                    id: batterySavingSwitch

                    automaticCheck: false
                    checked: simpleSettingsSection.batterySavingSwitchChecked
                    enabled: locationSettings.locationEnabled && AccessPolicy.locationSettingsEnabled

                    //% "Battery-saving mode"
                    text: qsTrId("settings_location-la-battery_saving_positioning")

                    //: Description of the battery-saving positioning mode
                    //% "Use online services instead of the GPS to calculate positioning information. Data costs may apply, but this mode uses less battery power."
                    description: qsTrId("settings_location-la-battery_saving_positioning_description")

                    onClicked: {
                        if (locationSettings.locationMode == LocationConfiguration.CustomMode) {
                            locationSettings.saveCustomSettings()
                        }

                        transitionTimer.batterySavingTransition = true
                        transitionTimer.start()
                        enableOnlineAgps(LocationConfiguration.BatterySavingMode)
                    }
                }
                TextSwitch {
                    id: deviceOnlySwitch

                    automaticCheck: false
                    checked: simpleSettingsSection.deviceOnlySwitchChecked
                    enabled: locationSettings.locationEnabled && AccessPolicy.locationSettingsEnabled

                    //% "Device-only mode"
                    text: qsTrId("settings_location-la-device_positioning")

                    //: Description of the device-only positioning mode
                    //% "Use the device GPS plus cell-tower information to calculate positioning information. This mode doesn't use any data."
                    description: qsTrId("settings_location-la-device_positioning_description")

                    onClicked: {
                        if (locationSettings.locationMode == LocationConfiguration.CustomMode) {
                            locationSettings.saveCustomSettings()
                        }

                        transitionTimer.deviceOnlyTransition = true
                        transitionTimer.start()
                        locationSettings.locationMode = LocationConfiguration.DeviceOnlyMode
                        root.checkFlightMode()
                    }
                }

                TextSwitch {
                    id: customSwitch

                    automaticCheck: false
                    checked: simpleSettingsSection.customSwitchChecked
                    enabled: locationSettings.locationEnabled && AccessPolicy.locationSettingsEnabled

                    //% "Custom settings"
                    text: qsTrId("settings_location-la-custom_positioning")

                    //: Description of the custom positioning settings mode
                    //% "Turn on or off specific positioning methods for maximum control over data usage and privacy."
                    description: qsTrId("settings_location-la-custom_positioning_description")

                    onClicked: {
                        if (locationSettings.locationMode != LocationConfiguration.CustomMode) {
                            locationSettings.locationMode = LocationConfiguration.CustomMode
                            locationSettings.restoreCustomSettings()
                            root.checkFlightMode()
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: selectCustomSettingsBtn.height + (2 * Theme.paddingLarge)
                    Button {
                        id: selectCustomSettingsBtn
                        enabled: locationSettings.locationEnabled
                                && locationSettings.locationMode == LocationConfiguration.CustomMode
                                && AccessPolicy.locationSettingsEnabled
                        anchors.centerIn: parent
                        //% "Select custom settings"
                        text: qsTrId("settings_location-bt-select_custom_positioning_settings")
                        onClicked: {
                            var obj = pageStack.animatorPush(advancedSettingsPageComponent)
                            obj.pageCompleted.connect(function(page) {
                                page.onStatusChanged.connect(function() { if (page.status == PageStatus.Deactivating) locationSettings.saveCustomSettings() })
                            })
                        }
                    }
                }
            }
        }
    }

    LocationConfiguration { id: locationSettings }

    function enableOnlineAgps(locationMode) {
        if (locationSettings.hereAvailable && locationSettings.mlsAvailable
                && locationSettings.hereState === LocationConfiguration.OnlineAGpsAgreementNotAccepted
                && locationSettings.mlsOnlineState === LocationConfiguration.OnlineAGpsAgreementNotAccepted) {
            pageStack.animatorPush(usageTermsComponent, {
                                       providerName: "here",
                                       locationMode: locationMode,
                                       acceptDestination: usageTermsComponent,
                                       acceptDestinationProperties: { providerName: "mls", locationMode: locationMode },
                                       acceptDestinationAction: PageStackAction.Replace
                                   })
        } else if (locationSettings.hereAvailable
                   && locationSettings.hereState === LocationConfiguration.OnlineAGpsAgreementNotAccepted) {
            pageStack.animatorPush(usageTermsComponent, { providerName: "here", locationMode: locationMode })
        } else if (locationSettings.mlsAvailable
                   && locationSettings.mlsOnlineState === LocationConfiguration.OnlineAGpsAgreementNotAccepted) {
            pageStack.animatorPush(usageTermsComponent, { providerName: "mls", locationMode: locationMode })
        } else {
            locationSettings.hereState = LocationConfiguration.OnlineAGpsEnabled
            locationSettings.mlsOnlineState = LocationConfiguration.OnlineAGpsEnabled
            // Set location mode directly as terms have been already agreed
            locationSettings.locationMode = locationMode
        }
    }

    function enableHereAgps() {
        if (locationSettings.hereState === LocationConfiguration.OnlineAGpsAgreementNotAccepted) {
            pageStack.animatorPush(usageTermsComponent, { providerName: "here" })
        } else {
            locationSettings.hereState = LocationConfiguration.OnlineAGpsEnabled
        }
    }

    function enableMlsOnlineAgps() {
        if (locationSettings.mlsOnlineState === LocationConfiguration.OnlineAGpsAgreementNotAccepted) {
            pageStack.animatorPush(usageTermsComponent, { providerName: "mls" })
        } else {
            locationSettings.mlsEnabled = true
            locationSettings.mlsOnlineState = LocationConfiguration.OnlineAGpsEnabled
        }
    }

    Component {
        id: usageTermsComponent

        Dialog {
            id: usageTermsDialog

            property string providerName
            property int locationMode: -1

            onAccepted: {
                if (providerName == "here") {
                    locationSettings.hereState = LocationConfiguration.OnlineAGpsEnabled
                } else {
                    locationSettings.mlsEnabled = true
                    locationSettings.mlsOnlineState = LocationConfiguration.OnlineAGpsEnabled
                }
                if (!acceptDestination && locationMode !== -1) {
                    // Delay setting the requested location mode until all terms have been agreed
                    // to, as changing the here/mls agreement states may have temporarily
                    // recalculated the locationMode beforehand.
                    locationSettings.locationMode = locationMode
                }
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: content.height

                Column {
                    id: content

                    width: parent.width

                    DialogHeader {
                        dialog: usageTermsDialog
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        color: Theme.secondaryHighlightColor
                        font.pixelSize: Theme.fontSizeLarge
                        wrapMode: Text.Wrap
                        //% "Accept terms and enable assisted positioning"
                        text: qsTrId("settings_location-he-location_terms")
                    }

                    Item {
                        width: parent.width
                        height: Theme.paddingLarge
                    }

                    Text {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        color: Theme.highlightColor
                        linkColor: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        text: usageTermsDialog.providerName == "here" ? locationSettings.hereAgreementText : locationSettings.mlsOnlineAgreementText
                        onLinkActivated: {
                            Qt.openUrlExternally(link)
                        }

                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }

    Component {
        id: agreementPageComponent

        Page {
            id: agreementPage

            property string providerName

            //% "Revoke HERE agreement"
            property string _hereMenuText: qsTrId("settings_location-me-revoke_here_agreement")

            //% "HERE usage agreement"
            property string _herePageHeaderText: qsTrId("settings_location-he-show_here_agreement_header")

            //% "Revoke Mozilla agreement"
            property string _mlsMenuText: qsTrId("settings_location-me-revoke_mls_agreement")

            //% "Mozilla usage agreement"
            property string _mlsPageHeaderText: qsTrId("settings_location-he-show_mls_agreement_header")

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: content.height

                PullDownMenu {
                    MenuItem {
                        text: providerName == "here" ? agreementPage._hereMenuText : agreementPage._mlsMenuText
                        onClicked: {
                            if (providerName == "here") {
                                locationSettings.hereState = LocationConfiguration.OnlineAGpsAgreementNotAccepted
                                locationSettings.locationMode = LocationConfiguration.CustomMode
                            } else {
                                locationSettings.mlsOnlineState = LocationConfiguration.OnlineAGpsAgreementNotAccepted
                                locationSettings.locationMode = LocationConfiguration.CustomMode
                            }
                            pageStack.pop()
                        }
                    }
                }

                Column {
                    id: content

                    width: parent.width

                    PageHeader {
                        title: providerName == "here" ? agreementPage._herePageHeaderText : agreementPage._mlsPageHeaderText
                    }

                    Text {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*x
                        color: Theme.highlightColor
                        linkColor: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeExtraSmall
                        wrapMode: Text.Wrap
                        textFormat: Text.StyledText
                        text: providerName == "here" ? locationSettings.hereAgreementText : locationSettings.mlsOnlineAgreementText
                        onLinkActivated: {
                            Qt.openUrlExternally(link)
                        }

                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }

    Component {
        id: advancedSettingsPageComponent
        Page {
            id: advancedSettingsPage
            canNavigateForward: false
            SilicaFlickable {
                anchors.fill: parent
                contentHeight: content.height

                Column {
                    id: content
                    width: parent.width
                    PageHeader {
                        id: header
                        //: Title of the "advanced" settings section
                        //% "Advanced settings"
                        title: qsTrId("settings_location-la-advanced_settings_section")
                    }
                    Column {
                        id: gpsColumn
                        visible: locationSettings.gpsAvailable
                        width: parent.width
                        SectionHeader {
                            //% "GPS"
                            text: qsTrId("settings_location-la-gps_section_header")
                        }
                        IconTextSwitch {
                            id: gpsSwitch

                            automaticCheck: false
                            checked: locationSettings.gpsEnabled
                            enabled: locationSettings.locationEnabled

                            icon.source: "image://theme/icon-m-gps"

                            //% "GPS positioning"
                            text: qsTrId("settings_location-la-gps_positioning")

                            //: Description of GPS positioning
                            //% "Enable GPS-positioning to pinpoint the device location to a high level of accuracy.  Extra battery usage will be incurred."
                            description: qsTrId("settings_location-gps_positioning_description")

                            onClicked: {
                                var newState = !checked
                                locationSettings.gpsEnabled = newState
                                root.checkFlightMode()
                            }
                        }
                    }

                    Column {
                        id: hereColumn
                        visible: locationSettings.hereAvailable
                        width: parent.width
                        SectionHeader {
                            //% "HERE GPS assistance"
                            text: qsTrId("settings_location-la-here_section_header")
                        }
                        TextSwitch {
                            id: hereSwitch

                            automaticCheck: false
                            checked: locationSettings.hereState === LocationConfiguration.OnlineAGpsEnabled
                            enabled: locationSettings.locationEnabled

                            //% "Faster position lock"
                            text: qsTrId("settings_location-la-here_positioning")

                            description: capabilityDataContextProperty.value || capabilityDataContextProperty.value === undefined
                                           // Description for devices with mobile data capability
                                           //% "Assist the main GPS with additional information available on the device and via the HERE service to allow faster location lock. Data cost may apply."
                                         ? qsTrId("settings_location-la-here_positioning_description")
                                           // Description for devices without mobile data capability
                                           //% "Assist the main GPS with additional information available on the device and via the HERE service to allow faster location lock."
                                         : qsTrId("settings_location-la-here_positioning_description_non-mobile-data")

                            onClicked: {
                                if (locationSettings.hereState === LocationConfiguration.OnlineAGpsEnabled) {
                                    locationSettings.hereState = LocationConfiguration.OnlineAGpsDisabled
                                } else {
                                    enableHereAgps()
                                }
                            }
                        }
                    }

                    Column {
                        id: mlsColumn
                        visible: locationSettings.mlsAvailable
                        width: parent.width
                        SectionHeader {
                            //% "Mozilla Location Services"
                            text: qsTrId("settings_location-la-mls_section_header")
                        }
                        TextSwitch {
                            id: mlsSwitch

                            automaticCheck: false
                            checked: locationSettings.mlsEnabled
                            enabled: locationSettings.locationEnabled

                            //% "Offline position lock from Mozilla Location Services cell-tower information"
                            text: qsTrId("settings_location-la-mls_positioning")

                            //: Description of the offline (cell-tower) position lock
                            //% "Calculate low-accuracy, cell-tower-based, offline positioning information. Some extra battery usage will be incurred."
                            description: qsTrId("settings_location-la-mls_positioning_description")

                            onClicked: {
                                var newState = !checked
                                locationSettings.mlsEnabled = newState
                            }
                        }
                        TextSwitch {
                            id: mlsOnlineSwitch

                            automaticCheck: false
                            checked: locationSettings.mlsEnabled && locationSettings.mlsOnlineState === LocationConfiguration.OnlineAGpsEnabled
                            enabled: locationSettings.locationEnabled && locationSettings.mlsEnabled

                            //% "Online position lock from Mozilla Location Services cell-tower plus wireless network information"
                            text: qsTrId("settings_location-la-mls_online_positioning")

                            description: capabilityDataContextProperty.value || capabilityDataContextProperty.value === undefined
                                           //: Description of the online (cell-tower plus wlan) Mozilla Location Services position lock for devices with mobile data capability
                                           //% "Calculate medium-accuracy, cell-tower plus wireless-network-based positioning information via online request. Data costs may apply."
                                         ? qsTrId("settings_location-la-mls_online_positioning_description")
                                           //: Description of the online (cell-tower plus wlan) Mozilla Location Services position lock for devices without mobile data capability
                                           //% "Calculate low-accuracy, wireless-network-based positioning information via online request."
                                         : qsTrId("settings_location-la-mls_online_positioning_description_non_mobile_data")

                            onClicked: {
                                if (locationSettings.mlsEnabled && locationSettings.mlsOnlineState === LocationConfiguration.OnlineAGpsEnabled) {
                                    locationSettings.mlsOnlineState = LocationConfiguration.OnlineAGpsDisabled
                                } else {
                                    enableMlsOnlineAgps()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ContextProperty {
        id: capabilityDataContextProperty
        key: "Cellular.CapabilityData"
    }
}
