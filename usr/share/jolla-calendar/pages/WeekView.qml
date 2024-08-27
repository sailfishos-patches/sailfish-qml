import QtQuick 2.6
import Sailfish.Silica 1.0
import "Util.js" as Util

Item {
    id: root

    readonly property alias date: weekPanel.currentDate
    readonly property string title: Util.capitalize(Format.formatDate(weekPanel.currentDate, Formatter.MonthNameStandalone))
    readonly property string description: {
        var now = new Date
        return now.getFullYear() != weekPanel.currentDate.getFullYear() ? weekPanel.currentDate.getFullYear() : ""
    }
    property alias flickable: flickable

    property Item tabHeader
    function attachHeader(tabHeader) {
        if (tabHeader) {
            tabHeader.parent = tabPlaceholder
        }
        root.tabHeader = tabHeader
    }
    function detachHeader() {
        root.tabHeader = null
    }
    function gotoDate(date) {
        weekPanel.date = date
    }

    SilicaFlickable {
        id: flickable

        anchors.fill: parent

        contentWidth: width
        contentHeight: tabPlaceholder.height + weekPanel.contentHeight
        contentY: weekPanel.initialContentY
        quickScroll: false

        property real pullDownMenuOrigin
        MouseArea {
            id: headerArea
            property bool within
            parent: flickable
            anchors.fill: parent
            z: 100
            onPressed: {
                within = mouse.y < tabPlaceholder.height + weekPanel.headerHeight
                mouse.accepted = false
            }
        }
        onDraggingVerticallyChanged: {
            if (draggingVertically && headerArea.within) {
                pullDownMenuOrigin = weekPanel.contentY
            }
        }
        Connections {
            target: pullDownMenu
            onActiveChanged: if (!pullDownMenu.active && !flickable.dragging) flickable.pullDownMenuOrigin = 0
        }
        onMovementEnded: if (pullDownMenu && !pullDownMenu.active) pullDownMenuOrigin = 0
        onTopMarginChanged: topMargin = pullDownMenu && pullDownMenu.active ? pullDownMenu.height - flickable.pullDownMenuOrigin : 0

        Column {
            id: content
            width: parent.width
            y: Math.max(flickable.contentY, flickable.pullDownMenuOrigin)
            Item {
                id: tabPlaceholder
                width: isPortrait ? parent.width : (parent.width / 2)
                x: isPortrait ? 0 : (parent.width / 2)
                height: (root.tabHeader ? root.tabHeader.height : 0)
            }

            Connections {
                target: tabHeader
                onDateClicked: {
                    var obj = pageStack.animatorPush("Sailfish.Silica.DatePickerDialog")
                    obj.pageCompleted.connect(function(page) {
                        page.accepted.connect(function() {
                            weekPanel.date = page.selectedDate
                        })
                    })
                }
            }

            WeekPanel {
                id: weekPanel
                width: parent.width
                height: root.height - tabPlaceholder.height
                Binding on contentY {
                    when: !flickable.pullDownMenu || (!flickable.pullDownMenu.active && flickable.pullDownMenuOrigin == 0)
                    value: flickable.contentY
                }
            }
        }
    }
}
