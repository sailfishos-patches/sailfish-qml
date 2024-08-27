import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Column {
    id: root

    property date date
    property int pageHeaderHeight

    // Make height calculations explicit. Column does not update its implicit
    // height when invisible. Cell height follows system font size changes
    height: pageHeaderHeight + 2*24*dayPage.cellHeight

    ConfigurationValue {
        id: timeFormatConfig
        key: "/sailfish/i18n/lc_timeformat24h"
    }

    Item {
        width: 1
        height: root.pageHeaderHeight

        Item {
            height: parent.height
            width: dayPage.width

            Rectangle {
                anchors.fill: parent
                color: Theme.primaryColor
                opacity: 0.15
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.highlightColor
                text: Format.formatDate(root.date, Formatter.DateFull)
                font.pixelSize: Theme.fontSizeMedium
            }
        }
    }

    Repeater {
        id: timesRepeater
        model: 24
        delegate: Item {
            width: timeLabel.x + timeLabel.width + Theme.paddingSmall // note: only label, background has page width
            height: dayPage.cellHeight * 2

            BackgroundItem {
                id: backgroundItem

                anchors.fill: timeRect
                onClicked: {
                    dayPage.timeClicked(getTime())
                }
                onPressAndHold: {
                    dayPage.timePressAndHold(getTime())
                }
                function getTime() {
                    var time = new Date(root.date.getTime())
                    time.setMinutes(time.getMinutes() + index * 60)
                    return time
                }
            }

            Rectangle {
                id: timeRect
                width: dayPage.width
                height: parent.height
                color: Theme.primaryColor
                opacity: 0.05
                visible: (index) & 1
            }

            Label {
                id: timeLabel
                x: Screen.sizeCategory > Screen.Medium ? Theme.horizontalPageMargin : Theme.paddingSmall
                height: parent.cellHeight
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Theme.fontSizeSmall
                color: backgroundItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                opacity: !((index) & 1) ? Theme.opacityLow : Theme.opacityHigh
                text: {
                    if (timeFormatConfig.value == "12") {
                        var hour = index % 12
                        if (hour == 0)
                            hour = 12

                        if (index % 6 == 0) {
                            var amPm = Format.formatArticle(index < 12 ? Formatter.AnteMeridiemIndicator
                                                                       : Formatter.PostMeridiemIndicator)
                            //: Hour pattern in day page flickable for 12h mode, %1 is hour, %2 is am/pm indicator,
                            //: shown at 12 and 6
                            //% "%1 %2"
                            return qsTrId("calendar_daypage_hour_indicator_12h_pattern").arg(hour.toLocaleString()).arg(amPm)
                        } else {
                            return hour.toLocaleString()
                        }
                    } else {
                        // FIXME: pattern not localized
                        var zero = Qt.locale().zeroDigit
                        return ((index < 10) ? zero : "") + index.toLocaleString() + ":" + zero + zero
                    }
                }
            }
        }
    }
}
