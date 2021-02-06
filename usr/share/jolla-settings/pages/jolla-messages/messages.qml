import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import MeeGo.QOfono 0.2
import com.jolla.messages.settings.translations 1.0
import org.nemomobile.ofono 1.0
import com.jolla.settings 1.0
import com.jolla.settings.system 1.0

ApplicationSettings {
    id: page

    // These rely on the detail that ApplicationSettings is still a page
    property bool pageReady: sailfishSimManager.ready || page.status == PageStatus.Active

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

    OfonoModemManager {
        id: modemManager
    }

    Column {
        width: parent.width
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

        ExpandingSectionGroup {
            enabled: !mainPlaceholder.enabled
            opacity: 1 - mainPlaceholder.opacity
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
