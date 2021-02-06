import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import org.nemomobile.alarms 1.0
import org.nemomobile.time 1.0
import org.nemomobile.configuration 1.0
import "main"

TabItem {
    id: root

    property real topMargin
    readonly property int availableWidth: width - 2 * (Theme.horizontalPageMargin - Theme.paddingLarge)
    readonly property int columnCount: Math.floor(availableWidth / Theme.itemSizeHuge)
    readonly property int itemWidth: availableWidth / columnCount

    anchors.fill: parent

    flickable: flickable
    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            MenuItem {
                //% "New alarm"
                text: qsTrId("clock-me-new_alarm")
                onClicked: mainPage.newAlarm(PageStackAction.Animated)
            }
        }

        ViewPlaceholder {
            //% "Pull down to save some alarms"
            text: qsTrId("clock-la-pull_down_to_save_alarms")
            enabled: alarmsModel.populated && alarms.count === 0
            anchors.top: column.bottom
        }

        Column {
            id: column

            x: Theme.horizontalPageMargin - Theme.paddingLarge
            width: parent.width - 2*x

            Item { width: 1; height: topMargin }

            Clock {
                id: clock
                enabled: (mainPage.status === PageStatus.Active || mainPage.status == PageStatus.Activating)
                         && mainWindow.applicationActive && root.isCurrentItem
            }
            Item {
                id: dateContainer
                anchors.horizontalCenter: parent.horizontalCenter
                width: dateText.width
                height: dateText.height + (Screen.sizeCategory > Screen.Medium ? Theme.itemSizeExtraSmall : Theme.paddingLarge)
                Label {
                    id: dateText
                    anchors {
                        top: parent.top
                        topMargin: -Theme.paddingMedium
                    }
                    color: Theme.highlightColor
                    text: {
                        var dateString = Format.formatDate(clock.time, Format.DateFull)
                        return dateString.charAt(0).toUpperCase() + dateString.substr(1)
                    }
                }
            }

            Grid {
                id: alarmsView

                columns: columnCount
                width: columns * itemWidth
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: alarmsModel.populated ? 1 : 0.01
                Behavior on opacity { FadeAnimation {} }

                Repeater {
                    id: alarms
                    delegate: AlarmItem {
                        id: alarmItem
                        width: itemWidth
                        menu: Component {
                            ClockContextMenu {
                                item: alarmItem
                            }
                        }
                    }
                    model: alarmsModel
                }
            }
        }
        VerticalScrollDecorator {}
    }
}

