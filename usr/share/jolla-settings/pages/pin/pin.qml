import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.ofono 1.0
import MeeGo.QOfono 0.2

Page {
    id: root

    OfonoModemManager {
        id: ofonoModemManager
    }

    SimManager {
        id: sailfishSimManager
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: pinSettings.height + Theme.paddingLarge

        SimActivationPullDownMenu {
            id: pullDownMenu
            showFlightModeAction: false // don't need flight mode off to change PIN settings
        }

        SimViewPlaceholder {
            id: mainPlaceholder
            simActivationPullDownMenu: pullDownMenu
        }

        Column {
            id: pinSettings
            width: parent.width
            enabled: !mainPlaceholder.enabled
            opacity: 1 - mainPlaceholder.opacity

            PageHeader {
                //: Header for page providing access to SIM PIN code settings
                //% "PIN code"
                title: qsTrId("settings_pin-he-pin_settings_header")
            }

            Repeater {
                id: modemPins

                model: ofonoModemManager.availableModems
                delegate: Column {
                    width: parent.width

                    SectionHeader {
                        id: simNameHeader
                        visible: Telephony.multiSimSupported
                        text: modemPin.multiModemIndex >= 0 ? sailfishSimManager.simNames[modemPin.multiModemIndex] : ""
                    }

                    SimSectionPlaceholder {
                        id: simPlaceholder
                        modemPath: modelData
                        simManager: modemPin.simManager
                        multiSimManager: sailfishSimManager
                    }

                    ModemPin {
                        id: modemPin
                        height: simPlaceholder.enabled ? 0 : implicitHeight + Theme.paddingLarge
                        opacity: 1 - simPlaceholder.opacity
                        enabled: !simPlaceholder.enabled

                        modemPath: modelData
                        multiModemIndex: sailfishSimManager.valid ? sailfishSimManager.indexOfModem(modelData) : -1
                        shortSimDescription: multiModemIndex >= 0 ? sailfishSimManager.modemSimModel.get(multiModemIndex).shortSimDescription : ""
                    }
                }
            }
        }
    }
}
