import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0  // BluetoothStatus
import com.jolla.lipstick 0.1 // LocationStatus
import "../main"              // EditableGridManager
import "../statusarea"        // FlightModeStatus, TetheringStatus, MobileDataStatus, WlanStatus

Item {
    id: root

    property alias columns: grid.columns
    property Item pager
    property int padding
    property alias userDefinedSwiches: dynamicSwitchModel.userDefinedSwiches

    width: parent.width
    height: grid.height

    Rectangle {
        anchors {
            fill: parent
            bottomMargin: -Theme.paddingMedium
        }
        z: -1
        color:Theme.highlightBackgroundColor
        opacity: gridManager.movingItem ? Theme.opacityFaint : 0.0
        Behavior on opacity {  FadeAnimator { } }
    }

    Connections {
        target: userDefinedSwiches
        onRowsRemoved: dynamicSwitchModel.updateAll()
        onRowsInserted: dynamicSwitchModel.updateAll()
    }

    Grid {
        id: grid

        columns: 3

        height: implicitHeight
        Behavior on height {
            enabled: !gridManager.itemResizing
            NumberAnimation { easing.type: Easing.InOutQuad }
        }

        DynamicSwitchModel {
            id: dynamicSwitchModel

            BluetoothStatus {
                id: bluetooth
                onConnectedChanged: dynamicSwitchModel.updateItem(bluetooth)
            }

            FlightModeStatus {
                id: flightMode
                onEnabledChanged: dynamicSwitchModel.updateItem(flightMode)
            }

            TetheringStatus {
                id: tethering
                onEnabledChanged: dynamicSwitchModel.updateItem(tethering)
            }

            LocationStatus {
                id: location
                onEnabledChanged: dynamicSwitchModel.updateItem(location)
            }

            MobileDataStatus {
                id: mobileData
                onConnectedChanged: dynamicSwitchModel.updateItem(mobileData)
            }

            WlanStatus {
                id: wlan
                onConnectedChanged: dynamicSwitchModel.updateItem(wlan)
            }

            VpnStatus {
                id: vpn
                onConnectedChanged: dynamicSwitchModel.updateItem(vpn)
            }
        }

        EditableGridManager {
            id: gridManager
            view: grid
            pager: root.pager
            contentContainer: root
            dragContainer: pager
            function itemAt(x, y) {
                return grid.childAt(x, y)
            }
            function itemCount() {
                return repeater.count
            }
            onScroll: pager.scroll(up)
            onStopScrolling: pager.stopScrolling()
        }

        Repeater {
            id: repeater

            model: dynamicSwitchModel
            delegate: FavoriteSettingsDelegate {
                manager: gridManager
                height: Theme.itemSizeLarge + 2*Theme.paddingLarge + contextMenuHeight
                width: Math.floor(root.width / root.columns)
                removeButtonVisible: false
            }
        }
    }
}
