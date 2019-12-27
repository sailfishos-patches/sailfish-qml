import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.voicecall.settings.translations 1.0
import Nemo.Configuration 1.0
import org.nemomobile.ofono 1.0
import com.jolla.settings.system 1.0
import MeeGo.QOfono 0.2
import MeeGo.Connman 0.2

Column {
    id: simCallSettings
    width: parent.width

    property alias callSettingsResponsePending: callSettings.responsePending
    property string modemPath
    property var simManager

    function applyVoiceMailSettings() {
        voiceMail.applySettings()
    }

    SimSectionPlaceholder {
        id: activateSimCardAction
        modemPath: simCallSettings.modemPath
        simManager: ofonoSimManager
        multiSimManager: simCallSettings.simManager
    }

    Column {
        id: simCallSettingsUiColumn
        width: parent.width
        height: enabled ? implicitHeight : 0
        enabled: !activateSimCardAction.enabled
        opacity: activateSimCardAction.valid ? 1 - activateSimCardAction.opacity : 0

        CallSettings {
            id: callSettings
            modemPath: simCallSettings.modemPath
            width: parent.width
        }

        ListItem {
            id: callForwarding
            Label {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                //% "Call forwarding"
                text: qsTrId("settings_phone-la-call_forwarding")
                color: callForwarding.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("CallForwarding.qml"),
                                      { "modemPath": simCallSettings.modemPath })
        }
        ListItem {
            id: callBarring
            Label {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                //% "Call barring"
                text: qsTrId("settings_phone-la-call_barring")
                color: callBarring.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            onClicked: pageStack.animatorPush(Qt.resolvedUrl("CallBarring.qml"),
                                      { "modemPath": simCallSettings.modemPath })
        }
        VoiceMail {
            id: voiceMail
            modemPath: simCallSettings.modemPath
            width: parent.width
        }
    }

    OfonoModem {
        id: ofonoModem
        modemPath: simCallSettings.modemPath
    }

    OfonoSimManager {
        id: ofonoSimManager
        modemPath: simCallSettings.modemPath
    }
}
