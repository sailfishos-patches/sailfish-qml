import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Nemo.Time 1.0
import "Util.js" as Util

Item {
    property alias date: datePicker.date
    property alias viewMoving: datePicker.viewMoving
    property string dstIndication: dstIndicator.visible
        && dstIndicator.transitionDay == date.getDate()
        ? dstIndicator.transitionDescription : ""

    property bool _largeScreen: Screen.sizeCategory > Screen.Medium

    width: parent.width
    height: datePicker.height + Theme.horizontalPageMargin

    WallClock {
        id: wallClock
        updateFrequency: WallClock.Day
    }

    DatePicker {
        id: datePicker

        property int indicatorWidth: 1.5 * Theme.paddingSmall
        property int indicatorSpacing: Theme.paddingSmall
        property int maxIndicatorCount: Math.min(5, (datePicker.cellWidth + indicatorSpacing - 2*Theme.paddingSmall) / (indicatorWidth + indicatorSpacing))

        anchors {
            top: parent.top
            topMargin: Theme.horizontalPageMargin
        }

        leftMargin: _largeScreen ? Theme.horizontalPageMargin : 0
        rightMargin: 0

        width: _largeScreen && isPortrait ? parent.width*0.6 : parent.width
        cellHeight: isPortrait ? cellWidth
            : Math.min(cellWidth, ((Screen.width - dayRowHeight - 2*anchors.topMargin) / 6))
        daysVisible: true
        monthYearVisible: !_largeScreen
        delegate: Component {
            MouseArea {
                id: mouseArea
                // noon time to protect against timezone screw ups
                property date modelDate: new Date(model.year, model.month-1, model.day, 12, 0)

                width: datePicker.cellWidth
                height: datePicker.cellHeight

                AgendaModel {
                    id: events
                    filterMode: AgendaModel.FilterMultipleEventsPerNotebook
                }

                Binding {
                    target: events
                    property: "startDate"
                    value: modelDate
                    when: !datePicker.viewMoving
                }

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: model.day.toLocaleString()
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: model.day === wallClock.time.getDate()
                                && model.month === wallClock.time.getMonth()+1
                                && model.year === wallClock.time.getFullYear()
                    color: {
                        if (model.day === datePicker.day &&
                            model.month === datePicker.month &&
                            model.year === datePicker.year) {
                            return Theme.highlightColor
                        } else if (label.font.bold) {
                            return Theme.highlightColor
                        } else if (model.month === model.primaryMonth) {
                            return Theme.primaryColor
                        }
                        return Theme.secondaryColor
                    }
                }

                Row {
                    spacing: datePicker.indicatorSpacing
                    anchors {
                        top: label.baseline
                        topMargin: Theme.paddingMedium
                        horizontalCenter: parent.horizontalCenter
                    }

                    Repeater {
                        model: events
                        Rectangle {
                            width: datePicker.indicatorWidth
                            height: width
                            radius: width/2
                            color: model.event.color
                            visible: model.index < datePicker.maxIndicatorCount
                        }
                    }
                }

                // TODO: How are we meant to switch to day view?
                onClicked: datePicker.date = modelDate

                Binding {
                    when: dstIndicator.transitionDay == model.day
                        && dstIndicator.transitionMonth == model.primaryMonth - 1
                        && dstIndicator.transitionYear == model.year
                    target: dstIndicator
                    property: "parent"
                    value: mouseArea
                }
            }
        }
        DstIndicator {
            id: dstIndicator
            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
                verticalCenterOffset: -textVerticalCenterOffset
            }
            referenceDateTime: new Date(datePicker.date.getFullYear(),
                                        datePicker.date.getMonth(), 1, 0, 0)
            visible: transitionMonth == datePicker.date.getMonth()
                && transitionYear == datePicker.date.getFullYear()
        }

        ChangeMonthHint {}
    }
}
