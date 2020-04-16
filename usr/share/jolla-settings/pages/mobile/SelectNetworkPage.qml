import QtQuick 2.0
import MeeGo.QOfono 0.2
import Sailfish.Silica 1.0
import Sailfish.Settings.Networking 1.0
import com.jolla.settings 1.0

Page {
    id: root

    property var registration
    property var operators

    property bool _scanning: registration.scanning || minScanDuration.running

    Component.onCompleted: if (!operators.count) registration.scan()

    Connections {
        target: registration
        onValidChanged: if (!registration.valid) pageStack.pop()
        onStatusChanged: if (registration.status === "registered") delayedPagePop.start()
        onScanningChanged: if (registration.scanning) minScanDuration.restart()
    }

    OfonoNetworkOperator {
        id: operator
        property bool registrationPending
        function register(path) {
            operatorPath = path
            if (valid && !registering) {
                registrationPending = false
                registerOperator()
            } else {
                registrationPending = true
            }
        }
        onValidChanged: {
            if (valid && !registering && registrationPending) {
                registrationPending = false
                registerOperator()
            }
        }
        onRegisterComplete: {
            registrationPending = false
            if (error === OfonoNetworkOperator.NoError) {
                if (registration.status === "registered" || registration.status === "roaming") {
                    delayedPagePop.start()
                    return
                }
            } else if (error != OfonoNetworkOperator.InProgressError) {
                errors.notify(SettingsControlError.ConnectionFailed)
            }
            networks.highlightItem.running = false
        }
    }

    SettingsErrorNotification {
        id: errors
        icon: "icon-system-connection-mobile"
    }

    SilicaListView {
        id: networks

        anchors.fill: parent
        header: PageHeader {
            id: pageHeader
            //: Select network page header
            //% "Networks"
            title: qsTrId("settings_network-he-networks")
        }
        width: root.width
        model: (_scanning || placeHolder.enabled) ? null : operators

        delegate: NetworkItemDelegate {
            id: delegate
            name: model.name
            status: model.status
            description: (model.country ? model.country : model.mcc) + " " + model.mnc
            rightMargin: (networks.highlightItem && networks.highlightItem.running) ? networks.highlightItem.width + Theme.paddingLarge * 2 : Theme.paddingLarge

            ListView.onAdd:SequentialAnimation {
                PropertyAction { target: delegate; property: "opacity"; value: 0 }
                PropertyAction { target: delegate; property: "x"; value: root.width }
                PauseAnimation { duration: index >= 0 ? index * 80 : 0 }
                ParallelAnimation {
                    FadeAnimation { target: delegate; duration: 300; to: 1 }
                    NumberAnimation { target: delegate; properties: "x"; easing.type: Easing.InOutQuad; duration: 300; to: 0 }
                }
            }

            onClicked: {
                networks.currentIndex = index
                networks.highlightItem.running = true
                operator.register(model.operatorPath)
            }
        }

        highlight: Component {
            BusyIndicator {
                x: networks.currentItem.width - width - Theme.paddingLarge
                y: networks.currentItem.y + Math.floor((networks.currentItem.height - height)/2)
                size: BusyIndicatorSize.Medium
                opacity: running ? 1.0 : 0.0
            }
        }

        highlightFollowsCurrentItem: false

        PullDownMenu {
            visible: !_scanning

            MenuItem {
                //: Search network again
                //% "Search again"
                text: qsTrId("settings_network-me-no_network_search_again")
                onClicked:  registration.scan()
            }
        }

        ViewPlaceholder {
            id: placeHolder
            enabled: !_scanning && !operators.count
            //: Select network error message
            //% "Oops there was no networks found."
            text: qsTrId("settings_network-he-no_network_found")
            //: Select network error hint
            //% "Pull down to search again"
            hintText: qsTrId("settings_network-he-network_search_again_hint")
        }

        VerticalScrollDecorator { }
    }

    BusyLabel {
        running: _scanning
        //: Searching networks busy indicator title
        //% "Searching"
        text: qsTrId("settings_network-he-network_searching_networks")
    }

    Timer {
        id: delayedPagePop
        interval: 750
        onTriggered: pageStack.pop()
    }

    Timer {
        id: minScanDuration
        interval: 2000
    }
}
