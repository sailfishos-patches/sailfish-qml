import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import org.nemomobile.time 1.0
import "Util.js" as Util

Column {
    id: datePickerContainer

    property alias date: datePicker.date
    property alias viewMoving: datePicker.viewMoving

    property bool _largeScreen: Screen.sizeCategory > Screen.Medium
    property real _landscapeHeightWithoutDatePicker: Screen.width - Theme.paddingMedium
                                                     - datePicker.height - datePicker.anchors.topMargin
    function _selectMonth() {
        var year = Math.max(1980, Math.min(2300, datePicker.date.getFullYear()))
        var obj = pageStack.animatorPush("CalendarYearPage.qml",
                                  { startYear: 1980, endYear: 2300, defaultYear: year })
        obj.pageCompleted.connect(function(page) {
            page.yearSelected.connect(function(year) {
                var d = datePicker.date
                d.setFullYear(year)
                datePicker.date = d
            })
        })
    }

    Item {
        width: parent.width - (_largeScreen && isLandscape ? Theme.horizontalPageMargin : 0)
        height: datePicker.height + Theme.horizontalPageMargin + (_largeScreen && isLandscape ? dateLabel.height : 0)

        Loader {
            id: dateLabel
            active: _largeScreen
            anchors {
                left: isPortrait ? datePicker.right : parent.left
                right: parent.right
            }
            sourceComponent: Column {
                width: parent.width
                // landscape only if date number text fit doesn't make text too small
                visible: isPortrait || (datePickerContainer._landscapeHeightWithoutDatePicker >= 2.5 * monthItem.height)
                Label {
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: isPortrait ? Theme.paddingSmall : Theme.horizontalPageMargin
                        rightMargin: isPortrait ? Theme.horizontalPageMargin : 0
                    }

                    fontSizeMode: Text.VerticalFit
                    font.pixelSize: Theme.fontSizeHuge * 4.5
                    height: isPortrait ? Math.min(implicitHeight, datePicker.height - monthItem.height)
                                       : Math.min(implicitHeight,
                                                  Math.max(datePickerContainer._landscapeHeightWithoutDatePicker - monthItem.height,
                                                           monthItem.height * 1.5))
                    renderType: Text.NativeRendering
                    text: date.getDate()
                    horizontalAlignment: isPortrait ? Text.AlignRight : Text.AlignLeft
                }

                BackgroundItem {
                    id: monthItem
                    width: parent.width
                    onClicked: _selectMonth()
                    Label {
                        anchors {
                            left: parent.left
                            right: parent.right
                            leftMargin: isPortrait ? Theme.paddingSmall : Theme.horizontalPageMargin
                            rightMargin: isPortrait ? Theme.horizontalPageMargin : 0
                            verticalCenter: parent.verticalCenter
                        }
                        fontSizeMode: Text.HorizontalFit
                        font.pixelSize: Theme.fontSizeExtraLarge
                        color: monthItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        //% "MMMM yyyy"
                        text: Qt.formatDate(date, qsTrId("calendar-date_pattern_month_year"))
                        horizontalAlignment: isPortrait ? Text.AlignRight : Text.AlignLeft
                    }
                }
            }
        }

        DatePicker {
            id: datePicker

            anchors {
                top: _largeScreen && isLandscape && dateLabel.item && dateLabel.item.visible
                     ? dateLabel.bottom : parent.top
                topMargin: Theme.horizontalPageMargin
            }

            leftMargin: _largeScreen ? Theme.horizontalPageMargin : 0
            rightMargin: 0

            width: _largeScreen ? (isPortrait ? parent.width*0.6 : parent.width) : parent.width
            daysVisible: true
            monthYearVisible: !_largeScreen
            delegate: Component {
                MouseArea {
                    // noon time to protect against timezone screw ups
                    property date modelDate: new Date(model.year, model.month-1, model.day, 12, 0)

                    width: datePicker.cellWidth
                    height: datePicker.cellHeight

                    AgendaModel { id: events }

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

                    Rectangle {
                        anchors.top: label.baseline
                        anchors.topMargin: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width / 5
                        radius: 2
                        height: 4
                        visible: events.count > 0
                        color: label.color
                    }

                    // TODO: How are we meant to switch to day view?
                    onClicked: datePicker.date = modelDate
                    onPressAndHold: if (!_largeScreen) contextMenu.open(menuLocation)
                }
            }
            ChangeMonthHint {}
        }
    }

    Item {
        id: menuLocation
        width: parent.width
        height: Math.max(contextMenu.height, 1)
        ContextMenu {
            id: contextMenu
            width: datePicker.width
            MenuItem {
                //% "Change year"
                text: qsTrId("calendar-me-change_year")
                onClicked: _selectMonth()
            }
        }
    }
}
