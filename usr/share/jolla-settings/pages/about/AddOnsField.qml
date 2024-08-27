import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Store 1.0
import Nemo.DBus 2.0

MouseArea {
    onClicked: settingsDbus.openAccountsPage()
    width: parent.width
    height: detail.height

    Component.onCompleted: {
        addOnModel.populate()
    }

    DetailItem {
        id: detail

        //% "Add-Ons"
        label: qsTrId("settings_about-la-add_ons")
        valueFont.italic: addOnModel.error

        function load() {
            var names = []
            if (addOnModel.populated) {
                var licenseActiveOnly = true
                names = addOnModel.displayNames(licenseActiveOnly)
            }
            if (addOnModel.error)
                value = addOnModel.error
            else if (names.length !== 0)
                value = names.join(Format.listSeparator)
            else
                value = "-"
        }
    }

    BusyIndicator {
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
        size: BusyIndicatorSize.ExtraSmall
        running: !addOnModel.populated
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active)
                addOnModel.populate()
        }
    }

    AddOnModel {
        id: addOnModel
        onPopulatedChanged: detail.load()
        onErrorChanged: detail.load()
    }

    DBusInterface {
        id: settingsDbus
        bus: DBus.SessionBus
        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"

        function openAccountsPage() {
            settingsDbus.call("showAccounts", [])
        }
    }
}
