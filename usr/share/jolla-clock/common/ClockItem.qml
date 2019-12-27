import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.time 1.0
import org.nemomobile.configuration 1.0

Row {
    id: root

    //: "translate as non-empty if am/pm indicator starts the 12h time pattern"
    //% ""
    property string startWithAp: qsTrId("jolla-clock-start_with_ap")
    property date time
    property color color: Theme.highlightColor
    property color secondaryColor: Theme.secondaryHighlightColor
    property int primaryPixelSize: Theme.fontSizeHuge
    property int secondaryPixelSize: primaryPixelSize / 2.5
    property real timeTextWidth: timeText.width
    property real ampmTextWidth: ampm.visible ? ampm.width : 0
    property alias timeFormatConfig: timeFormatConfig

    layoutDirection: (startWithAp !== "" && startWithAp !== "jolla-clock-start_with_ap") ?  Qt.RightToLeft : Qt.LeftToRight

    Text {
        id: timeText

        // Glyphs larger than 100 or look poorly in the default rendering mode
        renderType: font.pixelSize > 100 ? Text.NativeRendering : Text.QtRendering

        color: root.color
        font { pixelSize: root.primaryPixelSize; family: Theme.fontFamilyHeading }
        anchors.verticalCenter: parent.verticalCenter
        text: {
            if (timeFormatConfig.value === "24") {
                return Format.formatDate(time, Format.TimeValueTwentyFourHours)
            } else {
                // this is retarded, yay for qt and js time formatting options
                var hours = time.getHours()
                if (hours === 0) {
                    hours = 12
                } else if (hours > 12) {
                    hours -= 12
                }

                //: Pattern for 12h time, h, hh, m, mm are supported, everything else left as is. escaping with ' not supported
                //% "h:mm"
                var result = qsTrId("jolla-clock-12h_time_pattern_without_ap")

                var zero = 0
                if (result.indexOf("hh") !== -1) {
                    var hourString = ""
                    if (hours < 10) {
                        hourString = zero.toLocaleString()
                    }
                    hourString += hours.toLocaleString()
                    result = result.replace("hh", hourString)
                } else {
                    result = result.replace("h", hours.toLocaleString())
                }

                var minutes = time.getMinutes()
                if (result.indexOf("mm") !== -1) {
                    var minuteString = ""
                    if (minutes < 10) {
                        minuteString = zero.toLocaleString()
                    }
                    minuteString += minutes.toLocaleString()
                    result = result.replace("mm", minuteString)
                } else {
                    result = result.replace("m", minutes.toLocaleString())
                }

                return result
            }
        }
    }

    Text {
        id: ampm

        anchors.baseline: timeText.baseline
        visible: timeFormatConfig.value !== "24"
        color: root.secondaryColor
        font { pixelSize: root.secondaryPixelSize; family: Theme.fontFamily; weight: Font.Bold }
        text: time.getHours() < 12
              //% "AM"
              ? qsTrId("jolla-clock-la-am")
              //% "PM"
              : qsTrId("jolla-clock-la-pm")
    }

    ConfigurationValue {
        id: timeFormatConfig
        key: "/sailfish/i18n/lc_timeformat24h"
    }
}
