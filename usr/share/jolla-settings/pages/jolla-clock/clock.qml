import QtQuick 2.6
import Sailfish.Silica 1.0
import org.sailfishos.clock.settings 1.0
import Nemo.Alarms 1.0
import com.jolla.settings 1.0

ApplicationSettings {
    property var snoozeDurations: [5, 10, 15, 30]
    readonly property int snoozeMinutes: Math.round(settings.snooze/60.0)

    AlarmSettings {
        id: settings

        onReadyChanged: {
            if (ready) {
                for (var i = 0; i < snoozeDurations.length; i++) {
                    if (snooze === (snoozeDurations[i] * 60)) {
                        snoozeComboBox.currentIndex = i
                        return
                    }
                }
                snoozeComboBox.currentIndex = -1
            }
        }
    }

    ComboBox {
        id: snoozeComboBox

        //% "Snooze duration"
        label: qsTrId("clock_settings-la-snooze_duration")
        value: currentItem ? currentItem.text
                           : //% "%0 minute(s)"
                             qsTrId("clock-la-minutes", snoozeMinutes).arg(snoozeMinutes)

        menu: ContextMenu {
            Repeater {
                model: snoozeDurations
                MenuItem {
                    //% "%0 minute(s)"
                    text: qsTrId("clock-la-minutes", modelData).arg(modelData)
                    onClicked: settings.snooze = modelData * 60 // from minutes to seconds
                }
            }
        }
    }
}
