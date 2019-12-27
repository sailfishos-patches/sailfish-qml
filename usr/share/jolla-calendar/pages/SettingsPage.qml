import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import Calendar.sortFilterModel 1.0
import Sailfish.Calendar 1.0

Page {
    property var excluded: new Array
    property bool excludedLoaded

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            loadExcluded()
            Calendar.excludedNotebooks = excluded
        }
    }

    function loadExcluded() {
        if (excludedLoaded)
            return

        var a = Calendar.excludedNotebooks
        for (var ii = 0; ii < a.length; ++ii)
            excluded.push(a[ii])

        excludedLoaded = true
    }

    function isNotebookExcluded(notebook) {
        loadExcluded()

        for (var ii = 0; ii < excluded.length; ++ii) {
            if (excluded[ii] == notebook)
                return true
        }
        return false
    }

    function setExcludeNotebook(notebook, exclude) {
        loadExcluded()

        var current = isNotebookExcluded(notebook)

        if (exclude && !current) {
            excluded.push(notebook);
        } else if (!exclude && current) {
            for (var ii = 0; ii < excluded.length; ++ii) {
                if (excluded[ii] == notebook) {
                    excluded.splice(ii, 1)
                    return;
                }
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                width: parent.width
                //% "Settings"
                title: qsTrId("calendar-settings-settings")
            }

            Repeater {
                model: SortFilterModel {
                    model: NotebookModel { }
                    sortRole: "name"
                }

                delegate: BackgroundItem {
                    id: backgroundItem

                    height: Math.max(calendarDelegate.height + 2*Theme.paddingSmall, Theme.itemSizeMedium)
                    highlighted: down || enabledSwitch.down

                    onClicked: enabledSwitch.checked = !enabledSwitch.checked

                    Switch {
                        id: enabledSwitch

                        down: backgroundItem.down || (pressed && containsMouse)
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.horizontalPageMargin - Theme.paddingLarge
                        anchors.verticalCenter: parent.verticalCenter
                        Component.onCompleted: checked = !isNotebookExcluded(uid)
                        onCheckedChanged: setExcludeNotebook(uid, !checked)
                    }

                    CalendarSelectorDelegate {
                        id: calendarDelegate
                        accountIcon: model.accountIcon
                        calendarName: localCalendar ? CommonCalendarTranslations.getLocalCalendarName() : model.name
                        calendarDescription: model.description

                        anchors.left: enabledSwitch.right
                        anchors.leftMargin: Theme.paddingMedium
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: notebookColor.left
                        anchors.rightMargin: Theme.paddingMedium
                    }

                    Component {
                        id: colorPicker
                        ColorPickerPage {
                            onColorClicked: {
                                model.color = color
                                pageStack.pop()
                            }
                        }
                    }

                    Rectangle {
                        id: notebookColor

                        opacity: enabledSwitch.checked ? 1.0 : Theme.opacityLow
                        anchors {
                            right: parent.right
                            rightMargin: Theme.horizontalPageMargin
                            verticalCenter: parent.verticalCenter
                        }
                        height: Theme.itemSizeExtraSmall
                        width: Theme.itemSizeExtraSmall
                        radius: Theme.paddingSmall/2
                        color: model.color

                        MouseArea {
                            enabled: enabledSwitch.checked
                            anchors { margins: -Theme.paddingLarge; fill: parent }
                            onClicked: pageStack.animatorPush(colorPicker)
                        }
                    }
                }
            }
        }
        VerticalScrollDecorator {}
    }
}
