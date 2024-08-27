import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0
import "Util.js" as Util

Page {
    id: root

    property date date

    SilicaListView {
        anchors.fill: parent
        header: Item {
            height: pageHeader.height + Theme.paddingLarge
            width: parent.width

            PageHeader {
                id: pageHeader
                title: Util.capitalize(Format.formatDate(root.date, Formatter.WeekdayNameStandalone))
            }
            Text {
                y: Theme.itemSizeSmall
                anchors {
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeMedium
                text: Format.formatDate(root.date, Formatter.DateLong)
            }
        }

        model: AgendaModel {
            startDate: root.date
            endDate: QtDate.addDays(root.date, 7)
        }

        delegate: DeletableListDelegate {}

        section {
            property: "sectionBucket"
            delegate: EventListSectionDelegate {
                onClicked: pageStack.animatorPush("DayPage.qml", {defaultDate: section})
            }
        }
        VerticalScrollDecorator {}
    }
}
