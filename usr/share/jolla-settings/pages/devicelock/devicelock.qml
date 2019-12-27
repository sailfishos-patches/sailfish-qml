import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.dbus 2.0
import org.nemomobile.devicelock 1.0

Page {
    id: page

    property variant _authenticationToken
    readonly property bool applicationActive: Qt.application.active
    readonly property bool settingsAvailable: securityCodeSettings.set
                && deviceLockSettings.authorization.status == Authorization.ChallengeIssued

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

        onAutomaticLockingChanged: lockingCombobox.currentIndex = lockingCombobox.updateIndex(deviceLockSettings.automaticLocking)
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
                currentIndex: updateIndex(deviceLockSettings.automaticLocking)

                menu: ContextMenu {
                    // If the context menu is opened in a sub-page the transition for opening the
                    // device lock sub-page will prevent the page being closed, or if there's a
                    // delay in opening the device lock page then the close animation could
                    // block it from opening. So we'll close the menu ourselves to get the timing
                    // right.
                    closeOnActivation: false

                    MenuItem {
                        //% "Not in use"
                        text: qsTrId("settings_devicelock-me-off")
                        visible: deviceLockSettings.maximumAutomaticLocking === -1
                        onClicked: lockingCombobox.setAutomaticLocking(-1)
                    }
                    MenuItem {
                        //% "No delay"
                        text: qsTrId("settings_devicelock-me-on0")
                        onClicked: lockingCombobox.setAutomaticLocking(0)
                    }
                    MenuItem {
                        //% "5 minutes"
                        text: qsTrId("settings_devicelock-me-on5")
                        visible: deviceLockSettings.maximumAutomaticLocking === -1
                                    || deviceLockSettings.maximumAutomaticLocking >= 5
                        onClicked: lockingCombobox.setAutomaticLocking(5)
                    }
                    MenuItem {
                        //% "10 minutes"
                        text: qsTrId("settings_devicelock-me-on10")
                        visible: deviceLockSettings.maximumAutomaticLocking === -1
                                    || deviceLockSettings.maximumAutomaticLocking >= 10
                        onClicked: lockingCombobox.setAutomaticLocking(10)
                    }
                    MenuItem {
                        //% "30 minutes"
                        text: qsTrId("settings_devicelock-me-on30")
                        visible: deviceLockSettings.maximumAutomaticLocking === -1
                                    || deviceLockSettings.maximumAutomaticLocking >= 30
                        onClicked: lockingCombobox.setAutomaticLocking(30)
                    }
                    MenuItem {
                        //% "60 minutes"
                        text: qsTrId("settings_devicelock-me-on60")
                        visible: deviceLockSettings.maximumAutomaticLocking === -1
                                    || deviceLockSettings.maximumAutomaticLocking >= 60
                        onClicked: lockingCombobox.setAutomaticLocking(60)
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
                            lockingCombobox.currentIndex = lockingCombobox.updateIndex(deviceLockSettings.automaticLocking)
                            if (menu) {
                                menu.close()
                            }
                        })
                    }
                }

                function updateIndex(value) {
                    if (value === -1) {
                        return 0
                    } else if (value === 0) {
                        return 1
                    } else if (value === 5) {
                        return 2
                    } else if (value === 10) {
                        return 3
                    } else if (value === 30) {
                        return 4
                    } else if (value === 60) {
                        return 5
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

            TextSwitch {
                id: peekSwitch
                //% "Allow feeds while locked"
                text: qsTrId("settings_devicelock-la-allow_feeds")
                //visible: securityCodeSettings.set
                visible: false // hidden until JB#27250 has been implemented.
                enabled: page.settingsAvailable
                automaticCheck: false
                checked: deviceLockSettings.peekingAllowed
                onClicked: {
                    page.authenticate(function(authenticationToken) {
                        deviceLockSettings.setPeekingAllowed(authenticationToken, !checked)
                    })
                }
            }

            TextSwitch {
                //: This switch chooses between Digit only keypad (current default behaviour) and new qwerty-keyboard for devicelock
                //% "Digit only keypad"
                text: qsTrId("settings_devicelock-la-digit_only_keypad")
                // [TMP HOTFIX] do not permit alphanum code to new users until proper fix is in place. Contributes to jb#24201
                // Those who already have enabled alphanumeric code right after update10, and want to revert back to numpad, a cmdline tool can be provided
                visible: false // securityCodeSettings.set
                enabled: page.settingsAvailable
                automaticCheck: false
                checked: !deviceLockSettings.codeInputIsKeyboard
                //: This description how to get digit only keypad back is showed when user has defined non-digit lockcode and he has qwerty enabled
                //% "You can only enable when your security code is digit only"
                description: !deviceLockSettings.codeCurrentIsDigitOnly ? qsTrId("settings_devicelock-la-busy-description") : ""
                onClicked: {
                    if (deviceLockSettings.codeCurrentIsDigitOnly || checked) {
                        page.authenticate(function(authenticationToken) {
                            deviceLockSettings.setInputIsKeyboard(authenticationToken, checked)
                        })
                    }
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
                visible: !securityCodeSettings.mandatory && (!deviceLockSettings.homeEncrypted || !securityCodeSettings.set)
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
