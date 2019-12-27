import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.devicelock 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: root

    // threshold above which we may reset without charger
    readonly property int batteryThreshold: 15
    readonly property bool batteryOk: batteryStatus.chargePercentage > batteryThreshold
    readonly property bool charging: batteryStatus.chargerStatus === BatteryStatus.Connected
    readonly property bool applicationActive: Qt.application.active
    property int clearOptions: !!rebootByDefault.value
            ? DeviceReset.Reboot
            : DeviceReset.Shutdown

    readonly property bool policyEnabled: !!resetPolicy.value

    property bool clearError

    function createBackupLink() {
        //: A link to Settings | System | Backup
        //: Action or verb that can be used for %1 in settings_reset-la-erase_device_warning and
        //: settings_reset-la-erase_device_description
        //: Strongly proposing user to do a backup.
        //% "Back up"
        var backup = qsTrId("settings_reset-la-back_up")
        return "<a href='backup'>" + backup + "</a>"
    }

    onApplicationActiveChanged: {
        if (!applicationActive) {
            deviceReset.authorization.relinquishChallenge()

            pageStack.pop(root)
        }
    }

    BatteryStatus {
        id: batteryStatus
    }

    DBusInterface {
        id: dsmeDbus
        bus: DBus.SystemBus
        service: "com.nokia.dsme"
        path: "/com/nokia/dsme/request"
        iface: "com.nokia.dsme.request"
    }


    DeviceReset {
        id: deviceReset

        onClearingDevice: dsmeDbus.call("req_reboot", [])
        onClearDeviceError: {
            if (!pageStack.busy) {
                pageStack.pop(root)
            } else {
                root.clearError = true
            }
        }
        authorization {
            onChallengeExpired: pageStack.pop(root)
        }
    }

    ConfigurationValue {
        id: rebootByDefault

        key: "/apps/jolla-settings-system/reset/reboot_default"
    }

    PolicyValue {
        id: resetPolicy

        policyType: PolicyValue.DeviceResetEnabled
    }

    Column {
        id: content

        width: parent.width

        PageHeader {
            //% "Reset"
            title: qsTrId("settings_reset-he-reset")
        }

        DisabledByMdmBanner {
            active: !root.policyEnabled
        }

        Item {
            id: batteryWarning

            width: parent.width - 2*Theme.horizontalPageMargin
            height: Math.max(batteryIcon.height, batteryText.height)
            x: Theme.horizontalPageMargin
            visible: !root.batteryOk && root.policyEnabled

            Image {
                id: batteryIcon
                anchors.verticalCenter: parent.verticalCenter
                source: "image://theme/icon-l-battery"
            }

            Label {
                id: batteryText

                anchors {
                    left: batteryIcon.right
                    leftMargin: Theme.paddingMedium
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                text: root.charging
                      ? //: Battery low warning for device reset when charger is attached.
                        //% "Battery level low. Do not remove the charger."
                        qsTrId("settings_reset-la-battery_charging")
                      : //: Battery low warning for device reset when charger is not attached.
                        //% "Battery level too low."
                        qsTrId("settings_reset-la-battery_level_low")
            }
        }

        Item {
            width: 1
            height: Theme.paddingLarge
            visible: batteryWarning.visible
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*Theme.horizontalPageMargin
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.highlightColor
            linkColor: Theme.primaryColor
            textFormat: Text.AutoText
            //: Takes "Back up" (settings_reset-la-back_up) formatted hyperlink as parameter.
            //: This is done because we're creating programmatically a hyperlink for it.
            //% "This will erase everything from the device and revert the software back to the factory state. "
            //% "This means losing everything you have added to the device, including updates, applications, accounts, contacts, photos and other media.<br><br>"
            //% "%1 user data before reset the device."
            text: qsTrId("settings_reset-la-erase_device_description").arg(createBackupLink())

            opacity: root.policyEnabled ? 1.0 : Theme.opacityLow
            onLinkActivated: pageStack.animatorPush("Sailfish.Vault.MainPage")
        }

        Item {
            width: parent.width
            height: Theme.paddingLarge
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            preferredWidth: Theme.buttonWidthMedium
            //% "Clear device"
            text: qsTrId("settings_reset-bt-clear_device")
            onClicked: {
                pageStack.animatorPush(clearDeviceComponent)
            }
            enabled: (root.batteryOk || root.charging) && root.policyEnabled
        }
    }

    Authenticator {
        id: deviceLock

        onAuthenticated: {
            deviceReset.clearDevice(authenticationToken, root.clearOptions)

            pageStack.animatorPush(clearingPage)
        }
        onAborted: {
            pageStack.pop(root)
        }
    }

    Component {
        id: clearDeviceComponent

        Dialog {
            id: dialog

            acceptDestination: deviceLock.availableMethods ? lockDialog : clearingPage
            canAccept: (root.batteryOk || root.charging)
                        && deviceReset.authorization.status == Authorization.ChallengeIssued

            onAccepted: {
                deviceLock.authenticate(
                            deviceReset.authorization.challengeCode,
                            deviceReset.authorization.allowedMethods)
            }

            onStatusChanged: {
                switch (status) {
                case PageStatus.Activating:
                case PageStatus.Active:
                    if (deviceReset.authorization.status == Authorization.NoChallenge) {
                        deviceReset.authorization.requestChallenge()
                    }
                    break
                default:
                    break
                }
            }

            SilicaFlickable {
                contentHeight: content.height
                anchors.fill: parent

                Column {
                    id: content

                    width: parent.width

                    DialogHeader {
                        dialog: dialog
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*Theme.horizontalPageMargin
                        height: implicitHeight + Theme.paddingLarge
                        font {
                            family: Theme.fontFamilyHeading
                            pixelSize: Theme.fontSizeExtraLarge
                        }
                        color: Theme.highlightColor
                        //% "Do you really want to clear device?"
                        text: qsTrId("settings_reset-la-clear_device")
                        wrapMode: Text.Wrap

                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*Theme.horizontalPageMargin
                        height: implicitHeight + Theme.paddingLarge
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.highlightColor
                        linkColor: Theme.primaryColor
                        //: Takes "Back up" (settings_reset-la-back_up) formatted hyperlink as parameter.
                        //: This is done because we're creating programmatically a hyperlink for it.
                        //% "Accepting this erases everything from your device and reverts the software back to factory state. "
                        //% "This means losing everything you have added to the device (e.g. updates, applications, accounts, contacts, photos and other media). "
                        //% "%1 files to memory card.<br><br>"
                        //% "When erasing, device will shut down automatically and the next boot up might take longer than usual."
                        text: qsTrId("settings_reset-la-erase_device_warning").arg(createBackupLink())
                        wrapMode: Text.Wrap
                        textFormat: Text.AutoText
                        onLinkActivated: pageStack.animatorPush("Sailfish.Vault.MainPage")
                    }

                    Label {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2*Theme.horizontalPageMargin
                        height: implicitHeight + Theme.paddingLarge
                        font.pixelSize: Theme.fontSizeExtraSmall
                        visible: deviceLock.availableMethods != Authenticator.NoAuthentication
                        color: Theme.highlightColor
                        //% "You will need to enter your security code before device can be cleared."
                        text: qsTrId("settings_reset-la-clear_device_security_code_notice")
                        wrapMode: Text.Wrap
                    }
                    Item {
                        width: 1
                        height: Theme.itemSizeSmall
                    }
                    TextSwitch {
                        //% "Reboot the device automatically after next reset."
                        text: qsTrId("settings_reset-la-reboot_after_reset")
                        automaticCheck: false
                        onClicked: root.clearOptions = root.clearOptions ^ DeviceReset.Reboot
                        checked: root.clearOptions & DeviceReset.Reboot
                        visible: deviceReset.supportedOptions & DeviceReset.Reboot
                    }
                    TextSwitch {
                        //% "Erase all data."
                        text: qsTrId("settings_reset-la-wipe-data")
                        //% "If this is set all data on the device will be overwritten. "
                        //% "This may take half an hour or longer depending on the device's storage capacity. "
                        //% "A normal factory reset will take closer to 5 minutes but some data may still be recoverable afterwards."
                        description: qsTrId("settings_reset-la-wipe-data-description")
                        automaticCheck: false
                        onClicked: root.clearOptions = root.clearOptions ^ DeviceReset.WipePartitions
                        checked: root.clearOptions & DeviceReset.WipePartitions
                        visible: deviceReset.supportedOptions & DeviceReset.WipePartitions
                    }
                }
            }
        }
    }

    Component {
        id: lockDialog

        DeviceLockInputPage {
        }
    }

    Component {
        id: clearingPage

        Page {
            backNavigation: false
            // this page flashes only briefly. avoiding real content

            onStatusChanged: {
                if (status == PageStatus.Active && root.clearError) {
                    root.clearError = false
                    pageStack.pop(root)
                }
            }
        }
    }
}
