import QtQuick 2.0
import Sailfish.Silica 1.0

ListModel {
    id: stopwatch

    property int totalTime
    property alias running: stopwatchTimer.running
    property bool hourMode: totalTime > 3600000 // an hour in milliseconds
    property date _startTime
    property date _lapStartTime

    ListElement { time: 0; splitTime: 0; lap: 1 }

    function start() {
        if (!running) {
            if (totalTime === 0) {
                _startTime = new Date()
                _lapStartTime = _startTime
            } else {
                var now = new Date()
                _startTime = new Date(now - totalTime)
                _lapStartTime = new Date(now - get(0).time)
            }
            running = true
        }
    }
    function pause() {
        running = false
    }
    function nextLap() {
        var now = new Date()
        get(0).time = now - _lapStartTime
        get(0).splitTime = now - _startTime
        _lapStartTime = now
        insert(0, {"time": 0, "splitTime": 0, "lap": count + 1 })
    }
    function reset() {
        pause()
        clear()
        append({"time": 0, "splitTime": 0, "lap": 1 })
        totalTime = 0
    }
    function formatTime(milliseconds) {
        var dateTime = new Date()
        dateTime.setMinutes(0)
        dateTime.setHours(0)
        dateTime.setSeconds(0)
        dateTime.setMilliseconds(milliseconds)
        var centiseconds = Math.floor(milliseconds/10) % 100
        var centisecondsString = centiseconds.toLocaleString()
        while (centisecondsString.length < 2) {
            var zero = 0
            centisecondsString = zero.toLocaleString() + centisecondsString
        }
        if (stopwatch.hourMode) {
            return Qt.formatDateTime(dateTime, "hh.mm:ss.") + centisecondsString
        } else {
            return Qt.formatDateTime(dateTime, "mm:ss.") + centisecondsString
        }
    }

    property Timer _timer: Timer {
        id: stopwatchTimer

        interval: 10
        repeat: true
        onTriggered: {
            var now = new Date()
            totalTime = now - _startTime
            get(0).time = now - _lapStartTime
            get(0).splitTime = now - _startTime
        }
    }
}
