import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import MeeGo.QOfono 0.2
import com.jolla.messages.settings.translations 1.0
import org.nemomobile.ofono 1.0
import com.jolla.settings.system 1.0

Page {
    id: mainPage
    property bool pageReady: sailfishSimManager.ready || mainPage.status == PageStatus.Active
    onPageReadyChanged: if (pageReady) pageReady = true // remove binding

    onStatusChanged: {
        if (status == PageStatus.Inactive) {
            for (var i = 0; i < simCardSettingsRepeater.count; ++i) {
                if (simCardSettingsRepeater.itemAt(i).simCardSettings != null) {
                    simCardSettingsRepeater.itemAt(i).simCardSettings.updateSmsc()
                }
            }
        }
    }

    SimManager {
        id: sailfishSimManager
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height
        enabled: pageReady
        Behavior on opacity { FadeAnimator {} }
        opacity: enabled ? 1.0 : 0.0

        SimActivationPullDownMenu {
            id: pullDownMenu
        }

        SimViewPlaceholder {
            id: mainPlaceholder
            simActivationPullDownMenu: pullDownMenu
        }

        OfonoModemManager {
            id: modemManager
        }

        Column {
            id: content
            width: parent.width
            enabled: !mainPlaceholder.enabled
            opacity: 1 - mainPlaceholder.opacity

            PageHeader {
                //: Messages settings page header
                //% "Messages"
                title: qsTrId("settings_messages-he-messages")
            }

            ExpandingSectionGroup {
                width: parent.width
                animateToExpandedSection: false
                currentIndex: sailfishSimManager.activeSim >= 0 ? sailfishSimManager.activeSim : 0

                Repeater {
                    id: simCardSettingsRepeater
                    width: parent.width
                    model: modemManager.availableModems

                    delegate: ExpandingSection {
                        buttonHeight: (title.length && modemManager.availableModems.length > 1) ? Theme.itemSizeMedium : 0 // hide section header if only one modem
                        title: sailfishSimManager.simNames[sailfishSimManager.indexOfModem(modelData)]
                        content.sourceComponent: Column {
                            width: parent.width

                            SimSectionPlaceholder {
                                id: simPlaceholder
                                modemPath: modelData
                                simManager: ofonoSimManager
                                multiSimManager: sailfishSimManager
                            }

                            SimCardMessagingSettings {
                                enabled: !simPlaceholder.enabled
                                opacity: 1 - simPlaceholder.opacity
                                height: enabled ? implicitHeight + Theme.paddingLarge : 0
                                modemPath: modelData
                                imsi: ofonoSimManager.subscriberIdentity
                            }

                            OfonoSimManager {
                                id: ofonoSimManager
                                modemPath: modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
