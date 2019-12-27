import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    property var importFromFile
    property var bluetoothPairing
    property var createAccount
    property var abandonImport

    SilicaFlickable {
        id: flickable
        width: parent.width
        height: parent.height
        contentWidth: width
        contentHeight: skipButton.y + skipButton.height + Theme.paddingMedium

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {}
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - x - Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font { pixelSize: Theme.fontSizeLarge }

                //: Select Lumia device
                //% "Which Lumia do you have?"
                text: qsTrId("contacts-la-select_lumia")
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - x - Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font { pixelSize: Theme.fontSizeMedium }

                //: Selection advice
                //% "Choose 'Other Lumia' if you have a Windows Phone 8 device"
                text: qsTrId("contacts-la-select_lumia_advice")
            }
            Column {
                width: parent.width

                ListModel {
                    id: devicesModel

                    Component.onCompleted: {
                        append({
                            //% "Lumia 510"
                            'name': qsTrId("contacts-la-lumia_510"),
                            'deviceType': 'wp75'
                        })
                        append({
                            //% "Lumia 610"
                            'name': qsTrId("contacts-la-lumia_610"),
                            'deviceType': 'wp75'
                        })
                        append({
                            //% "Lumia 710"
                            'name': qsTrId("contacts-la-lumia_710"),
                            'deviceType': 'wp75'
                        })
                        append({
                            //% "Lumia 800"
                            'name': qsTrId("contacts-la-lumia_800"),
                            'deviceType': 'wp75'
                        })
                        append({
                            //% "Lumia 900"
                            'name': qsTrId("contacts-la-lumia_900"),
                            'deviceType': 'wp75'
                        })
                        append({
                            //% "Other Lumia"
                            'name': qsTrId("contacts-la-lumia_other"),
                            'deviceType': 'wp8'
                        })
                    }
                }

                Repeater {
                    model: devicesModel

                    ListItem {
                        width: parent.width

                        Label {
                            id: label
                            anchors.centerIn: parent
                            color: highlighted ? Theme.highlightColor : Theme.primaryColor
                            wrapMode: Text.Wrap
                            text: model.name
                        }

                        onClicked: {
                            pageStack.animatorPush('ImportFromDeviceType.qml', {
                                'importFromFile': importFromFile,
                                'bluetoothPairing': bluetoothPairing,
                                'createAccount': createAccount,
                                'abandonImport': abandonImport,
                                'deviceType': model.deviceType
                            })
                        }
                    }
                }
            }
        }

        Button {
            id: skipButton
            anchors.horizontalCenter: parent.horizontalCenter

            //: Cancel import procedure
            //% "Skip importing"
            text: qsTrId("contacts-bt-skip_importing")
            y: Math.max(flickable.height - (height + Theme.itemSizeMedium), contentColumn.y + contentColumn.height + Theme.paddingLarge)

            onClicked: abandonImport()
        }
    }
}
