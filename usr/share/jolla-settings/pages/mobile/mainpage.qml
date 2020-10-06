import QtQuick 2.0
import MeeGo.QOfono 0.2
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import Sailfish.Telephony 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.ofono 1.0
import Sailfish.Settings.Networking 1.0
import MeeGo.Connman 0.2

Page {
    id: root

    property Item dataSimSelector
    property bool pageReady: sailfishSimManager.ready || status == PageStatus.Active
    onPageReadyChanged: if (pageReady) pageReady = true // remove binding

    Component.onCompleted: {
        dataSimSelector = Telephony.multiSimSupported
                ? Qt.createQmlObject("import com.jolla.settings.multisim 1.0; DataSimSelector {}", topSettingsContainer)
                : undefined
    }

    SimManager {
        id: sailfishSimManager
        controlType: SimManagerType.Data
    }

    OfonoModemManager {
        id: modemManager
    }

    OfonoNetworkRegistration {
        id: networkRegistration

        // this object is only used for the PageHeader in single-modem mode
        modemPath: Telephony.multiSimSupported ? "" : modemManager.defaultVoiceModem
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        VerticalScrollDecorator {}

        SimActivationPullDownMenu {
            id: pullDownMenu
            multiSimManager: sailfishSimManager
            enabled: !disabledByMdmBanner.active
            visible: true

            MenuItem {
                // Menu item for opening the advanced network configuration page
                //% "Advanced"
                text: qsTrId("settings_network-me-mobile_advanced")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("../advanced-networking/mainpage.qml"))
            }
        }

        SimViewPlaceholder {
            id: mainPlaceholder
            simActivationPullDownMenu: pullDownMenu
        }

        Column {
            id: content
            width: parent.width
            // Note: don't link enabled state to disabledByMdmBanner.active
            // otherwise (due to enabled property inheritance) the SimSectionPlaceholder
            // will always be disabled even when no SIM is in the slot, when locked
            // due to the Policy.  Instead, disable sub-columns / elements separately.
            enabled: !mainPlaceholder.enabled
            opacity: 1 - mainPlaceholder.opacity

            PageHeader {
                title: {
                    if (!Telephony.multiSimSupported && networkRegistration.name.length > 0) {
                        return networkRegistration.name
                    }
                    //: Mobile network setting page header
                    //% "Mobile network"
                    return pageReady ? qsTrId("settings_network-he-mobile_network") : ""
                }
            }

            DisabledByMdmBanner {
                id: disabledByMdmBanner
                active: !AccessPolicy.mobileNetworkSettingsEnabled
            }

            Column {
                id: topSettingsContainer
                width: parent.width
                enabled: !disabledByMdmBanner.active

                property bool topSettingsAvailable: root.pageReady && (!Telephony.multiSimSupported || sailfishSimManager.availableSimCount > 0)

                opacity: topSettingsAvailable ? (disabledByMdmBanner.active ? Theme.opacityHigh : 1) : 0
                height: topSettingsAvailable
                        ? implicitHeight
                        : 0
                clip: true
                Behavior on height {
                    enabled: root.status == PageStatus.Active && !tetherWarningAnimation.running
                    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                }
                // FadeAnimator, animating in render thread, breaks if started
                // before window ready to render. So, do not use it here.
                // See bug #43341
                Behavior on opacity { FadeAnimation {} }

                SectionHeader {
                    id: mobileDataHeader
                    //: Mobile data settings section
                    //% "Mobile data"
                    text: qsTrId("settings_network-he-mobile_data")
                }

                MobileDataSwitch {
                    id: mobileDataSwitch
                    modemPath: modemManager.defaultDataModem

                    onRequestDataSim: {
                        if (dataSimSelector.enabled) {
                            dataSimRequested = true
                            dataSimSelector.show()
                        }
                    }

                    Connections {
                        target: dataSimSelector
                        onClosed: {
                            if (mobileDataSwitch.dataSimRequested) {
                                mobileDataSwitch.updateDefaultDataSim()
                                mobileDataSwitch.requestConnect()
                            }
                            mobileDataSwitch.dataSimRequested = false
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
                    //% "Mobile data may be used in the background and may incur data transfer costs."
                    text: qsTrId("settings_network-la-mobile_data_description")
                }

                InfoLabel {
                    id: tetherWarning

                    //% "Internet sharing is on. Devices will lose internet connectivity if mobile data is turned off."
                    text: qsTrId("settings_network-la-mobile_data_internet_sharing_warning")
                    opacity: enabled ? 1 : 0
                    enabled: mobileDataSwitch.checked && wifiTechnology.tethering
                    font.pixelSize: Theme.fontSizeLarge

                    height: enabled ? implicitHeight : 0
                    clip: true

                    Behavior on height {
                        enabled: root.status == PageStatus.Active

                        NumberAnimation {
                            id: tetherWarningAnimation
                            duration: 200; easing.type: Easing.InOutQuad
                        }
                    }

                    Behavior on opacity { FadeAnimation {} }
                }
            }

            Repeater {
                model: modemManager.availableModems

                delegate: Column {
                    width: parent.width

                    SectionHeader {
                        text: Telephony.multiSimSupported ? sailfishSimManager.simNames[sailfishSimManager.indexOfModem(modelData)] || "" : ""
                        visible: Telephony.multiSimSupported
                        opacity: disabledByMdmBanner.active ? Theme.opacityHigh : 1
                        enabled: !disabledByMdmBanner.active
                    }

                    SimSectionPlaceholder {
                        id: simPlaceholder
                        modemPath: Telephony.multiSimSupported ? modelData : "" // single-modem mode uses full-page placeholder instead
                        multiSimManager: sailfishSimManager
                        opacity: enabled ? (disabledByMdmBanner.active ? Theme.opacityHigh : 1) : 0
                    }

                    SimMobileNetworkSettings {
                        enabled: !simPlaceholder.enabled && !disabledByMdmBanner.active
                        height: simPlaceholder.enabled ? 0 : (implicitHeight + Theme.paddingLarge)
                        opacity: disabledByMdmBanner.active ? (Theme.opacityHigh - simPlaceholder.opacity) : (1 - simPlaceholder.opacity)
                        modemPath: modelData
                        showMMSHeader: !Telephony.multiSimSupported
                        showNetworkHeader: !Telephony.multiSimSupported
                    }
                }
            }
        }
    }

    NetworkManager {
        id: networkManager
    }

    NetworkTechnology {
        id: wifiTechnology
        path: networkManager.WifiTechnology
    }
}
