import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.clock.private 1.0

Item {
    id: root

    property date time
    property QtObject timerClock

    // Size of the clock border decoration as a fraction of the radius
    property real _faceRadiusBase: 84
    property real _faceHourLength: 14.736 / _faceRadiusBase
    property real _faceMinuteLength: 7.367 / _faceRadiusBase

    Image {
        id: clockFace

        anchors.fill: parent
        fillMode: Image.PreserveAspectFit
        source: "image://theme/graphic-clock-face-3"
    }

    ShaderEffect {
        id: timerVisualization

        anchors.fill: clockFace

        visible: _stopwatchMode && stopwatch || timerClock && timerClock.alarm

        property date startTime: {
            if (_stopwatchMode && stopwatch)
                return stopwatch._startTime
            else if (timerClock && timerClock.alarm)
                return time
            else
                return new Date
        }
        onStartTimeChanged: _updateTimerVisualization()
        property date endTime: {
            if (_stopwatchMode && stopwatch)
                return time
            else if (timerClock && timerClock.alarm)
                return new Date(1000*timerClock.alarm.triggerTime)
            else
                return new Date
        }
        onEndTimeChanged: _updateTimerVisualization()

        property int _seconds: {
            if (_stopwatchMode && stopwatch)
                return stopwatchView.seconds
            else if (timerClock)
                return timerClock.remaining
            else
                return 60
        }
        on_SecondsChanged: _updateTimerVisualization()

        property real outerRadius: 1
        property real innerRadius: 1 - _faceHourLength
        property real startAngle
        property real endAngle

        property color highlightColor: Theme.rgba(Theme.highlightColor, Theme.opacityOverlay)

        function _updateTimerVisualization() {
            var duration = endTime - startTime

            if (_stopwatchMode) {
                var minutes = Math.floor((_seconds/60) % 60)
                startAngle = 0
                if (_seconds < 60) {
                    endAngle = 2 * Math.PI * _seconds/60
                } else {
                    endAngle = 2 * Math.PI * minutes/60
                }
                innerRadius = 1 - _faceMinuteLength
            } else if (_seconds < 60) {
                startAngle = 2 * Math.PI * (1 - _seconds/60)
                endAngle = 2 * Math.PI
                innerRadius = 1 - _faceMinuteLength
            } else if (duration >= 12*60*60*1000) {
                startAngle = 0
                endAngle = 0
                innerRadius = outerRadius
            } else if (duration >= 60*60*1000) {
                startAngle = 2 * Math.PI * _hoursToAngle(startTime)
                var end = 2 * Math.PI * _hoursToAngle(endTime)
                endAngle = end > startAngle ? end : end + 2 * Math.PI
                innerRadius = 1 - _faceHourLength
            } else if (duration > 0) {
                startAngle = 2 * Math.PI * _minutesToAngle(startTime)
                var end = 2 * Math.PI * _minutesToAngle(endTime)
                endAngle = end > startAngle ? end : end + 2 * Math.PI
                innerRadius = 1 - _faceMinuteLength
            } else {
                startAngle = 0
                endAngle = 0
                innerRadius = outerRadius
            }
        }

        vertexShader: "
            uniform highp mat4 qt_Matrix;
            attribute highp vec4 qt_Vertex;
            attribute highp vec2 qt_MultiTexCoord0;
            varying highp vec2 coord;
            void main() {
                coord = qt_MultiTexCoord0;
                gl_Position = qt_Matrix * qt_Vertex;
            }"
        fragmentShader: "
            varying highp vec2 coord;
            uniform lowp float qt_Opacity;
            uniform lowp float outerRadius;
            uniform lowp float innerRadius;
            uniform lowp float startAngle;
            uniform lowp float endAngle;
            uniform lowp vec4 highlightColor;

            lowp float PI = 3.14159265358979323846264;

            void main() {
                highp vec2 vector = 2.0*(coord - vec2(0.5, 0.5));
                lowp float radius = length(vector);
                if (innerRadius < radius && radius < outerRadius) {
                    lowp float angle = atan(vector.y, vector.x) + PI/2.0;
                    angle += angle < 0.0 ? 2.0*PI : 0.0;
                    if (startAngle < angle && angle < endAngle) {
                        gl_FragColor = highlightColor;
                        return;
                    }
                    angle += 2.0*PI;
                    if (startAngle < angle && angle < endAngle) {
                        gl_FragColor = highlightColor;
                        return;
                    }
                }

                gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
            }"
    }

    Rectangle {
        id: hourHand

        anchors {
            bottom: clockFace.verticalCenter
            bottomMargin: -radius
            horizontalCenter: clockFace.horizontalCenter
        }

        visible: !largeTimer.visible
        color: Theme.primaryColor

        height: clockFace.height * 0.25
        width: 7 * Theme.pixelRatio
        radius: width/2

        transform: Rotation {
            origin.x: hourHand.width/2
            origin.y: hourHand.height - hourHand.radius
            angle: 360 * _hoursToAngle(time)
        }
    }

    Rectangle {
        id: minuteHand

        anchors {
            bottom: clockFace.verticalCenter
            bottomMargin: -radius
            horizontalCenter: clockFace.horizontalCenter
        }

        visible: !largeTimer.visible
        color: Theme.primaryColor

        height: clockFace.height * 0.37
        width: 7 * Theme.pixelRatio
        radius: width/2

        transform: Rotation {
            origin.x: minuteHand.width/2
            origin.y: minuteHand.height - minuteHand.radius
            angle: 360 * _minutesToAngle(time)
        }
    }

    Label {
        id: largeTimer

        anchors.centerIn: clockFace
        color: Theme.highlightColor
        visible: (_stopwatchMode && stopwatch) || timerVisualization._seconds < 60

        states: [ State {
                when: timerVisualization._seconds < 60 // Show before one minute
                PropertyChanges {
                    target: largeTimer

                    font.pixelSize: clockFace.height*0.56
                    text: timerVisualization._seconds

                }
            },

            State {
                when: (timerVisualization._seconds >= 60) && (timerVisualization._seconds < 60*60) //  Show after minutes
                PropertyChanges {
                    target: largeTimer

                    font.pixelSize: clockFace.height*0.32
                    text: Qt.formatTime(new Date(0, 0, 0, 0, 0, timerVisualization._seconds), "mm:ss")
                }
            },

            State {
                when: timerVisualization._seconds >= 60*60 // Show after hours
                PropertyChanges {
                    target: largeTimer

                    font.pixelSize: clockFace.height*0.2
                    text: Qt.formatTime(new Date(0, 0, 0, 0, 0, timerVisualization._seconds), "hh:mm:ss")
                }
            }
        ]
    }

    Repeater {
        id: alarmIndicators

        model: !_stopwatchMode ? enabledAlarmsModel : undefined

        Rectangle {
            property date _time: {
                var date = new Date
                date.setHours(model.alarm.hour)
                date.setMinutes(model.alarm.minute)
                return date
            }

            visible: index < alarmsView.visualCount

            anchors {
                verticalCenter: clockFace.verticalCenter
                verticalCenterOffset: clockFace.height * (_faceMinuteLength - 1)/2
                horizontalCenter: clockFace.horizontalCenter
            }

            height: Theme.iconSizeSmall
            width: Theme.paddingSmall
            radius: width/2
            color: Clock.hueShift(index, alarmIndicators.count, Theme.highlightColor)

            transform: Rotation {
                origin.x: width/2
                origin.y: height/2 - anchors.verticalCenterOffset
                angle: 360 * _hoursToAngle(_time)
            }
        }
    }

    function _hoursToAngle(time) {
        var minutes = (time.getHours() % 12) * 60 + time.getMinutes()
        return minutes / (12 * 60)
    }

    function _minutesToAngle(time) {
        return time.getMinutes() / 60
    }
}

