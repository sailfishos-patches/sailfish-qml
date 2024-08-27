import QtQuick 2.0
import Nemo.Time 1.0

WallClock {
    id: timer

    property bool active
    property int seconds: 0
    property bool keepRunning
    property real progress: seconds / duration
    property int remaining: duration - seconds

    property QtObject alarm: model.alarm
    property int elapsed: alarm ? alarm.elapsed : 0
    property int duration: alarm ? alarm.hour * 3600 + alarm.minute * 60 + alarm.second : 0
    property bool alarmEnabled: alarm ? alarm.enabled : false

    function reset() {
        seconds = 0
    }

    onElapsedChanged: seconds = elapsed
    onAlarmEnabledChanged: {
        seconds = elapsed
        active = alarmEnabled
    }
    onTimeChanged: {
        if (alarm && alarm.triggerTime > 0) {
            var tmp = (alarm.triggerTime*1000) - time.getTime()
            seconds = Math.round((duration*1000 - tmp)/1000)

            if (seconds > duration) {
                seconds = 0
            }
        }
    }

    enabled: active && keepRunning
    updateFrequency: WallClock.Second
}
