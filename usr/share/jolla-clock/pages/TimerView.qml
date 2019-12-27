import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import org.nemomobile.alarms 1.0
import org.nemomobile.notifications 1.0
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
                //% "Reset all"
                text: qsTrId("clock-me-reset_all")
                onClicked: timersModel.reset()
            }
            MenuItem {
                //% "New timer"
                text: qsTrId("clock-me-new_timer")
                onClicked: mainPage.newTimer(PageStackAction.Animated)
            }
        }

        ViewPlaceholder {
            //% "Pull down to save some timers"
            text: qsTrId("clock-la-pull_down_to_save_timers")
            enabled: alarmsModel.populated && timersModel.populated && timers.count === 0
        }

        Column {
            id: column
            x: Theme.horizontalPageMargin - Theme.paddingLarge
            width: parent.width - 2*x

            Item { width: 1; height: topMargin }
            Grid {
                id: timersView

                columns: columnCount
                width: columns * itemWidth
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: timersModel.populated ? 1 : 0.01
                Behavior on opacity { FadeAnimation {} }

                Repeater {
                    id: timers
                    delegate: TimerItem {
                        id: timerItem
                        width: itemWidth
                        menu: Component {
                            ClockContextMenu {
                                item: timerItem
                            }
                        }
                    }
                    model: timersModel
                }
            }
        }
        VerticalScrollDecorator {}
    }
}

