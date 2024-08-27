import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import com.jolla.settings.system 1.0
import Nemo.DBus 2.0
import org.nemomobile.devicelock 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: page

    property variant _authenticationToken
    readonly property bool applicationActive: Qt.application.active
    readonly property bool settingsAvailable: securityCodeSettings.set
                && deviceLockSettings.authorization.status == Authorization.ChallengeIssued
    readonly property var automaticLockingOptions: [-1, 0, 5, 10, 30, 60, 254]

    function addFingerprint() {
        pageStack.animatorPush(fingerprintSettings.fingers.count > 0
                    ? "com.jolla.settings.system.FingerEnrollmentDialog"
                    : "com.jolla.settings.system.FingerEnrollmentWelcomeDialog", {
            "settings": fingerprintSettings
        })
    }

    function removeFingerprint(fingerId) {
        deviceLockQuery.authenticate(fingerprintSettings.fingers.authorization, function(authenticationToken) {
            fingerprintSettings.fingers.remove(authenticationToken, fingerId)
            fingerprintSettings.fingers.authorization.relinquishChallenge()
        })
    }

    function authenticate(onAuthenticated, onCanceled) {
        if (page._authenticationToken) {
            onAuthenticated(page._authenticationToken)
        } else {
            deviceLockQuery.authenticate(deviceLockSettings.authorization, function(authenticationToken) {
                page._authenticationToken = authenticationToken
                onAuthenticated(authenticationToken)
            }, onCanceled)
        }
    }

    function automaticLockingText(minutes) {
        if (minutes < 0) {
            //% "Not in use"
            //: Device locking is disabled (or lock code has not been defined)
            return qsTrId("settings_devicelock-me-off")
        }
        if (minutes == 0) {
            //% "No delay"
            //: Device is to be locked immediately whenever display turns off
            return qsTrId("settings_devicelock-me-on0")
        }
        if (minutes >= 254) {
            //% "Manual"
            //: Device is to be locked only when user explicitly locks it
            return qsTrId("settings_devicelock-me-on-manual")
        }
        //% "%n minutes"
        //: Device is to be locked automatically after N minutes of inactivity
        return qsTrId("settings_devicelock-me-on-minutes", minutes)
    }

    onApplicationActiveChanged: {
        if (applicationActive) {
            deviceLockSettings.authorization.requestChallenge()
        } else {
            _authenticationToken = undefined

            fingerprintSettings.cancelAcquisition()
            fingerprintSettings.authorization.relinquishChallenge()

            deviceLockSettings.authorization.relinquishChallenge()

            deviceLockQuery.cancel()
            securityCodeSettings.cancel()
        }
    }

    onStatusChanged: {
        switch (status) {
        case PageStatus.Activating:
        case PageStatus.Active:
            if (deviceLockSettings.authorization.status == Authorization.NoChallenge) {
                deviceLockSettings.authorization.requestChallenge()
            }
            break
        default:
            break
        }
    }

    DeviceLockSettings {
        id: deviceLockSettings

        authorization {
            onChallengeExpired: {
                deviceLockSettings.authorization.requestChallenge()
            }
        }

        onMaximumAttemptsChanged: {
            attemptsSlider.value = deviceLockSettings.maximumAttempts != -1 ? deviceLockSettings.maximumAttempts : attemptsSlider.maximumValue
        }
    }

    FingerprintSensor {
        id: fingerprintSettings
    }

    DeviceLockQuery {
        id: deviceLockQuery

        returnOnAccept: true
        returnOnCancel: true
    }

    SecurityCodeSettings {
        id: securityCodeSettings

        onChanged: {
            page._authenticationToken = authenticationToken
        }
    }

    WindowGestureOverride {
        active: fingerprintSettings.acquiring
    }

    UserInfo {
        id: userInfo
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        Column {
            id: content
            width: parent.width
            anchors.left: parent.left
            anchors.right: parent.right

            PageHeader {
                //% "Device lock"
                title: qsTrId("settings_devicelock-he-devicelock")
            }

            ComboBox {
                id: lockingCombobox

                enabled: page.settingsAvailable
                width: parent.width
                //% "Automatic locking"
                label: qsTrId("settings_devicelock-la-status_combobox")
                value: automaticLockingText(deviceLockSettings.automaticLocking)
                Binding {
                    target: lockingCombobox
                    property: "currentIndex"
                    value: page.automaticLockingOptions.indexOf(deviceLockSettings.automaticLocking)
                }

                menu: ContextMenu {
                    // If the context menu is opened in a sub-page the transition for opening the
                    // device lock sub-page will prevent the page being closed, or if there's a
                    // delay in opening the device lock page then the close animation could
                    // block it from opening. So we'll close the menu ourselves to get the timing
                    // right.
                    closeOnActivation: false

                    Repeater {
                        model: page.automaticLockingOptions
                        MenuItem {
                            text: automaticLockingText(modelData)
                            onClicked: lockingCombobox.setAutomaticLocking(modelData)
                            visible: deviceLockSettings.maximumAutomaticLocking < 0 || deviceLockSettings.maximumAutomaticLocking >= modelData
                        }
                    }
                }

                function setAutomaticLocking(minutes) {
                    if (securityCodeSettings.set && deviceLockSettings.automaticLocking !== minutes) {
                        page.authenticate(function(authenticationToken) {
                            deviceLockSettings.setAutomaticLocking(authenticationToken, minutes)
                            if (menu) {
                                menu.close()
                            }
                        }, function() {
                            if (menu) {
                                menu.close()
                            }
                        })
                    }
                }
            }

            TextSwitch {
                id: notificationSwitch
                //% "Show notification banners when device is locked"
                text: qsTrId("settings_devicelock-la-show_notification")
                enabled: page.settingsAvailable
                automaticCheck: false
                checked: deviceLockSettings.showNotifications
                onClicked: {
                    page.authenticate(function(authenticationToken) {
                        deviceLockSettings.setShowNotifications(authenticationToken, !checked)
                    })
                }
            }

            Column {
                width: parent.width
                visible: fingerprintSettings.hasSensor

                SectionHeader {
                    //% "Fingerprint"
                    text: qsTrId("settings_devicelock-he-fingerprint")
                }

                Label {
                    x: Theme.horizontalPageMargin
                    width: parent.width - (2 * Theme.horizontalPageMargin)
                    height: implicitHeight + Theme.paddingMedium
                    wrapMode: Text.Wrap

                    //% "Unlock the device using fingerprint recognition"
                    text: qsTrId("settings_devicelock-la-use_fingerprint")

                    opacity: securityCodeSettings.set ? Theme.opacityHigh : Theme.opacityLow
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.highlightColor
                }

                Repeater {
                    model: fingerprintSettings.fingers

                    ListItem {
                        id: printDelegate

                        onClicked: openMenu()
                        /* JB#41218 Support renaming of fingerprints
                        onClicked: {
                            var obj = pageStack.animatorPush(Qt.resolvedUrl("FingerSettingsPage.qml"), {
                                "fingerprintSettings": fingerprintSettings,
                                "fingerprintId": fingerprintId,
                                "fingerprintName": nameLabel.text,
                                "acquisitionDate": acquisitionDate
                            })
                            obj.pageCompleted.connect(function(p) {
                                p.removeFinger.connect(page.removeFingerprint)
                            })
                        }
                        */

                        menu: Component {
                            ContextMenu {
                                MenuItem {
                                    //% "Delete"
                                    text: qsTrId("settings_devicelock-me-delete")
                                    onClicked: page.removeFingerprint(fingerprintId)
                                }
                            }
                        }

                        Label {
                            id: nameLabel
                            anchors {
                                left: parent.left
                                leftMargin: Theme.horizontalPageMargin
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            truncationMode: TruncationMode.Fade
                            color: printDelegate.highlighted ? Theme.highlightColor : Theme.primaryColor

                            text: fingerprintName != ""
                                    ? fingerprintName
                                    //% "Fingerprint %1"
                                    : qsTrId("settings_devicelock-la-fingerprint_name").arg(index + 1)
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Theme.paddingLarge
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    preferredWidth: Theme.buttonWidthLarge
                    //% "Add a fingerprint"
                    text: qsTrId("settings_devicelock-la-add_finger")
                    onClicked: page.addFingerprint()
                }
            }

            SectionHeader {
                //% "Security code"
                text: qsTrId("settings_devicelock-he-security_code")
            }

            TextSwitch {
                //% "Use device security code"
                text: qsTrId("settings_devicelock-la-use_security_code")
                //% "Unlock the device using a security code"
                description: qsTrId("settings_devicelock-la-use_security_code_description")

                automaticCheck: false
                checked: securityCodeSettings.set
                visible: !securityCodeSettings.mandatory && ((!deviceLockSettings.homeEncrypted && userInfo.alone) || !securityCodeSettings.set)
                onClicked: {
                    if (securityCodeSettings.set) {
                        securityCodeSettings.clear()
                    } else {
                        securityCodeSettings.change(deviceLockSettings.authorization.challengeCode)
                    }
                }
            }

            Slider {
                id: attemptsSlider
                value: deviceLockSettings.maximumAttempts != -1 ? deviceLockSettings.maximumAttempts : maximumValue
                minimumValue: 4
                maximumValue: deviceLockSettings.absoluteMaximumAttempts !== -1
                        ? deviceLockSettings.absoluteMaximumAttempts
                        : 51
                stepSize: 1
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                valueText: (deviceLockSettings.absoluteMaximumAttempts !== -1 || value < maximumValue)
                        ? value.toFixed(0)
                        //% "No limit"
                        : qsTrId("settings_devicelock-me-nolimit")
                visible: securityCodeSettings.set
                //% "Number of attempts"
                label: qsTrId("settings_devicelock-la-attempts_combobox")
                onDownChanged: {
                    var new_value = (deviceLockSettings.absoluteMaximumAttempts != -1 || value != maximumValue)
                            ? value
                            : -1

                    if (!down && deviceLockSettings.maximumAttempts != new_value) {
                        page.authenticate(function(authenticationToken) {
                            deviceLockSettings.setMaximumAttempts(authenticationToken, new_value)
                        }, function() {
                            attemptsSlider.value = deviceLockSettings.maximumAttempts != -1
                                    ? deviceLockSettings.maximumAttempts
                                    : attemptsSlider.maximumValue
                        })
                    }
                }
            }

            Item {
                width: parent.width
                height: Theme.paddingLarge * 2
            }
            Button {
                id: changeSecurityCodeBox
                enabled: page.settingsAvailable
                visible: securityCodeSettings.set
                anchors.horizontalCenter: parent.horizontalCenter
                preferredWidth: Theme.buttonWidthLarge
                //% "Change device security code"
                text: qsTrId("settings_devicelock-he-change_security_code")
                onClicked: securityCodeSettings.change(deviceLockSettings.authorization.challengeCode)
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge
            }
        }
    }
}
