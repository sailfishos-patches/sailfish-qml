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

                //: Select phone prompt
                //% "Select your previous phone"
                text: qsTrId("contacts-la-select_phone")
            }
            Column {
                width: parent.width

                ListModel {
                    id: devicesModel

                    Component.onCompleted: {
                        append({
                            //: Import from a Lumia
                            //% "Lumia"
                            'name': qsTrId("contacts-la-import_from_lumia"),
                            'deviceType': 'lumia'
                        })
                        append({
                            //: Import from an Android
                            //% "Android"
                            'name': qsTrId("contacts-la-import_from_android"),
                            'deviceType': 'android'
                        })
                        append({
                            //: Import from an iPhone
                            //% "iPhone"
                            'name': qsTrId("contacts-la-import_from_iphone"),
                            'deviceType': 'iphone'
                        })
                        append({
                            //: Import from another phone
                            //% "Other"
                            'name': qsTrId("contacts-la-import_from_other")
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
                            var props = {
                                'importFromFile': importFromFile,
                                'bluetoothPairing': bluetoothPairing,
                                'createAccount': createAccount,
                                'abandonImport': abandonImport
                            }
                            if (model.deviceType) {
                                if (model.deviceType == 'lumia') {
                                    pageStack.animatorPush('SelectLumia.qml', props)
                                } else {
                                    props['deviceType'] = model.deviceType
                                    pageStack.animatorPush('ImportFromDeviceType.qml', props)
                                }
                            } else {
                                pageStack.animatorPush('ImportFromOther.qml', props)
                            }
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
