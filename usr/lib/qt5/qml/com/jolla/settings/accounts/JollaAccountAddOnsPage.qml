import QtQuick 2.0
import Sailfish.Accounts 1.0
import Sailfish.Silica 1.0
import Sailfish.Store 1.0
import com.jolla.settings.accounts 1.0

Page {
    id: root

    AddOnModel {
        id: activeAddOns
        licenseStateFilter: AddOnModel.LicenseActiveOnly
        Component.onCompleted: populate()
    }

    AddOnModel {
        id: inactiveAddOns
        licenseStateFilter: AddOnModel.LicenseInactiveOnly
        Component.onCompleted: populate()
    }

    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active) {
                activeAddOns.populate()
                inactiveAddOns.populate()
            }
        }
    }

    PageBusyIndicator {
        running: !activeAddOns.populated || !inactiveAddOns.populated
    }

    SilicaFlickable {
        anchors.fill: parent

        Column {
            width: parent.width

            PageHeader {
                //: Heading for page that lists Add-Ons to Sailfish OS
                //% "Sailfish Add-Ons"
                title: qsTrId("settings_accounts-he-add_ons_page")
            }

            SectionHeader {
                visible: activeAddOns.count > 0
                //: Heading for section that lists Add-Ons with active license
                //% "My"
                text: qsTrId("settings_accounts-he-my_add_ons")
            }

            Repeater {
                model: activeAddOns
                delegate: itemComponent
            }

            SectionHeader {
                visible: inactiveAddOns.count > 0
                //: Heading for section that lists Add-Ons without active license
                //% "Available"
                text: qsTrId("settings_accounts-he-available_add_ons")
            }

            Repeater {
                model: inactiveAddOns
                delegate: itemComponent
            }

            Item {
                width: 1
                height: Theme.paddingLarge
            }

            Label {
                x: Theme.horizontalPageMargin
                width: root.width - 2*x
                visible: inactiveAddOns.populated && !inactiveAddOns.error
                    && inactiveAddOns.count == 0 && activeAddOns.count > 0
                font {
                    pixelSize: Theme.fontSizeLarge
                    family: Theme.fontFamilyHeading
                }
                color: palette.secondaryHighlightColor
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                //% "All Add-Ons available for your device are enabled"
                text: qsTrId("settings_accounts-la-no_more_add_ons")
            }
        }

        ViewPlaceholder {
            enabled: activeAddOns.populated
                && ((activeAddOns.count == 0 && inactiveAddOns.count == 0)
                    || activeAddOns.error)
            text: activeAddOns.error
                ? activeAddOns.error
                //% "No Add-On available for your device"
                : qsTrId("settings_accounts-la-no_add_on")
        }
    }

    Component {
        id: itemComponent
        ListItem {
            id: item

            width: parent.width
            contentHeight: Math.max(contentColumn.height, image.height) + Theme.paddingMedium

            menu: licenseActive ? null : contextMenu

            property int fontSize: Screen.sizeCategory > Screen.Medium ? Theme.fontSizeMedium : Theme.fontSizeSmall
            property int smallFontSize: Screen.sizeCategory > Screen.Medium ? Theme.fontSizeSmall : Theme.fontSizeExtraSmall
            property int iconSize: Screen.sizeCategory > Screen.Medium ? Theme.iconSizeLauncher : Theme.iconSizeMedium

            onClicked: openMenu()

            Image {
                id: image
                width: height
                height: item.iconSize
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                source: icon
                onStatusChanged: {
                    if (status == Image.Error)
                        console.log("Error loading image. source: " + source)
                }
            }

            Column {
                id: contentColumn
                anchors {
                    left: image.right
                    leftMargin: Theme.paddingMedium
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }

                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: item.fontSize
                    text: displayName
                }

                Label {
                    width: parent.width
                    text: summary
                    font.pixelSize: item.smallFontSize
                    wrapMode: Text.Wrap
                    truncationMode: TruncationMode.Fade
                }
            }

            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        //% "Get this Add-On"
                        text: qsTrId("settings_accounts-me-get_add_on")
                        onClicked: Qt.openUrlExternally(shopLink)
                    }
                }
            }
        }
    }
}
