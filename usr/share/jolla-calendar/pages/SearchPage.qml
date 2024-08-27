import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Calendar 1.0
import org.nemomobile.calendar 1.0

Page {
    SilicaListView {
        id: view

        anchors.fill: parent

        header: Column {
            width: parent.width
            PageHeader {
                //% "Search"
                title: qsTrId("jolla-calendar-he-search")
            }
            SearchField {
                width: parent.width - x
                x: Theme.horizontalPageMargin
                enabled: !view.model.loading
                //% "Search calendars"
                placeholderText: qsTrId("jolla-calendar-la-search_notebooks")
                EnterKey.onClicked: {
                    view.model.searchString = text
                    focus = false
                }
                onTextChanged: {
                    if (text.length == 0) {
                        view.model.searchString = ""
                        forceActiveFocus()
                    }
                }
                Component.onCompleted: forceActiveFocus()
            }
        }

        model: EventSearchModel {
            limit: 200
        }

        section {
            property: "year"
            delegate: Label {
                width: parent.width - Theme.paddingLarge
                height: Theme.itemSizeSmall
                color: Theme.highlightColor
                text: section
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }

        delegate: DeletableListDelegate {
            width: parent.width
            timeText: {
                var label = Format.formatDate(model.occurrence.startTime, Formatter.DateMediumWithoutYear)
                if (!model.event.allDay) {
                    label += " " + Format.formatDate(model.occurrence.startTime, Formatter.TimeValue)
                }
                return label
            }
        }

        ViewPlaceholder {
            enabled: view.model.count == 0 && view.model.searchString.length > 0 && !view.model.loading
            //% "No search results"
            text: qsTrId("jolla-calendar-la-search_no_result")
        }

        VerticalScrollDecorator {}
    }
    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: view.model.loading
    }
}
