/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Settings.Networking 1.0
import com.jolla.startupwizard 1.0
import com.jolla.settings.system 1.0
import Nemo.Configuration 1.0
import org.nemomobile.devicelock 1.0

import QOfono 0.2
import Sailfish.AccessControl 1.0
import Sailfish.Policy 1.0

ApplicationWindow {
    id: root

    readonly property string _accountName: "Jolla"
    property Page _accountPage
    property bool _internetConnectionSkipped
    property int _modemIndex
    property bool _pinRequested
    property var _fingerprintAuthenticationToken
    property bool _enteredTutorial

    property Component _firstPageAfterPinQuery: {
        if (reachedTutorialConf.value === true) {
            return tutorialMainComponent
        } else if (deviceLockSettings.homeEncrypted || DeviceLock.state != DeviceLock.Unlocked || !DeviceLock.enabled) {
            return mandatorySecurityCodeComponent
        } else {
            return _firstPageAfterUnlock
        }
    }
    property Component _firstPageAfterUnlock: networkCheckComponent

    property Component _pageAfterAccountSetup: fingerprintSettings.hasSensor
            ? fingerEnrollmentComponent
            : tutorialMainComponent

    readonly property Component tutorialMainComponent: {
        var tutorial = Qt.createComponent(pageStack.resolveImportPage("Sailfish.Tutorial.TutorialEntryPage"))
        if (tutorial.status != Component.Ready) {
            console.log("No Tutorial installed, skipping.")
            tutorial = noTutorialComponent
        }

        return tutorial
    }

    function _setInitialPage(showSimPinQuery) {
        ofonoInitTimeout.stop()
        var pageComponent = showSimPinQuery ? pinQueryComponent : _firstPageAfterPinQuery
        var page = pageStack.replace(pageComponent, {}, PageStackAction.Immediate)
    }

    function _accountSetupPage() {
        if (root._internetConnectionSkipped) {
            return root._pageAfterAccountSetup
        } else if (accountFactory.item && accountFactory.item.jollaAccountExists()) {
            // Store exists for account (TODO JB#47405 : should be fixed for jolla-settings-account)
            console.log("User already has a", _accountName, "account, skipping", _accountName,
                        "account creation. (Ignore the upcoming 'Great, your", _accountName,
                        "account was added' message.)")
            // This is only used if a store account already exists when the SUW is run; otherwise, the
            // Settings account creation flow takes care of triggering this flow.
            return Qt.createComponent(Qt.resolvedUrl("SUWWizardPostAccountCreationDialog.qml"))
        } else {
            return _createStoreAccountPage()
        }
    }

    function _createStoreAccountPage() {
        if (root._accountPage) {
            root._accountPage.destroy()
        }
        var props = { "wizardMode": true, "runningFromSettingsApp": false }
        root._accountPage = accountCreationManager.item
                ? accountCreationManager.item.accountCreationPageForProvider(_accountName.toLowerCase(), props)
                : null
        return root._accountPage || root._pageAfterAccountSetup
    }

    function tutorialExitConf() {
        if (!reachedTutorialConf.value) {
            reachedTutorialConf.value = true
            reachedTutorialConf.sync()

            // this is the last page that will definitely be seen, so set this now
            personalizedNaming.personalizeBroadcastNames()
        }
    }

    allowedOrientations: Orientation.Portrait
    _defaultLabelFormat: Text.PlainText

    initialPage: busyWaitComponent

    Connections {
        target: pageStack
        onCurrentPageChanged: {
            // detect if we entered the tutorial
            if (!root._enteredTutorial && pageStack.currentPage.hasOwnProperty("allowSystemGesturesBetweenLessons")) {
                root._enteredTutorial = true
                // don't allow back navigation from the tutorial
                pageStack.currentPage.backNavigation = false
                tutorialExitConf()
            }
        }
    }

    Component {
        id: busyWaitComponent
        Page {
            Rectangle {
                anchors.fill: parent
                color: "black"
            }
            PageBusyIndicator {
                running: true
            }
        }
    }

    StartupWizardManager {
        id: wizardManager
    }

    Loader {
        id: accountCreationManager

        source: Qt.resolvedUrl("SUWAccountCreationManager.qml")
    }

    Loader {
        id: accountFactory

        source: Qt.resolvedUrl("SUWAccountFactory.qml")
    }

    ScreenBlank {
    }

    ConfigurationValue {
        id: reachedTutorialConf
        key: "/apps/jolla-startupwizard/reached_tutorial"
    }

    PersonalizedNamingSetup {
        id: personalizedNaming
    }

    Timer {
        id: ofonoInitTimeout
        running: true
        interval: 10 * 1000
        onTriggered: {
            root._setInitialPage(false)
        }
    }

    OfonoManager {
        id: ofonoManager

        function _checkAvailable() {
            if (available) {
                if (available && modems.length) {
                    ofonoSimManager.modemPath = ofonoManager.modems[_modemIndex]
                } else {
                    // No modems, so PIN query is unnecessary, and OfonoSimManager will never become valid.
                    root._setInitialPage(false)
                }
            }
        }

        Component.onCompleted: _checkAvailable()
        onAvailableChanged: _checkAvailable()
    }

    OfonoSimManager {
        id: ofonoSimManager

        function _checkValid() {
            if (valid) {
                // when valid=true, pinRequired will have been set.
                if (ofonoSimManager.pinRequired == OfonoSimManager.SimPin
                        || ofonoSimManager.pinRequired == OfonoSimManager.SimPuk) {
                    root._setInitialPage(true)
                } else if (++_modemIndex < ofonoManager.modems.length) {
                    ofonoSimManager.modemPath = ofonoManager.modems[_modemIndex]
                } else {
                    if (_pinRequested)
                        pageStack.animatorReplace(_firstPageAfterPinQuery)
                    else
                        root._setInitialPage(false)
                }
            }
        }

        Component.onCompleted: _checkValid()
        onValidChanged: _checkValid()
    }

    FingerprintSensor {
        id: fingerprintSettings
    }

    DeviceLockSettings {
        id: deviceLockSettings
    }

    Component {
        id: pinQueryComponent
        WizardSimPinQuery {
            modemPath: ofonoSimManager.modemPath

            Component.onCompleted: _pinRequested = true
            onQueryDone: {
                if (++_modemIndex < ofonoManager.modems.length) {
                    ofonoSimManager.modemPath = ofonoManager.modems[_modemIndex]
                } else {
                    pageStack.animatorReplace(_firstPageAfterPinQuery)
                }
            }
        }
    }

    Component {
        id: networkCheckComponent

        NetworkCheckDialog {
            readonly property bool dateTimeSettingsEnabled: AccessPolicy.dateTimeSettingsEnabled
                                                            && AccessControl.hasGroup(AccessControl.RealUid, "sailfish-datetime")

            acceptDestination: dateTimeComponent

            //% "Setting up your internet connection at this point is highly recommended"
            headingText: qsTrId("startupwizard-he-internet_connection_heading")

            //% "With an internet connection you can set up your Store account and download essential apps now. "
            //% "You'll also be able to access the Store and OS updates immediately after setting up your account."
            bodyText: _accountPage ? qsTrId("startupwizard-la-internet_connection_body") : ""

            skipText: (_accountPage
                       ? //: Skip text if user doesn't want to set up the internet connection at the moment.
                         //: (Text surrounded by %1 and %2 is underlined and colored differently)
                         //% "%1Skip%2 internet connection setup and set up my Store account later"
                         qsTrId("startupwizard-la-skip_internet_connection_account_specific")
                       : //: Skip text if user doesn't want to set up the internet connection at the moment.
                         //: (Text surrounded by %1 and %2 is underlined and colored differently)
                         //% "%1Skip%2 internet connection setup"
                         qsTrId("startupwizard-la-skip_internet_connection"))
                    .arg("<u><font color=\"" + (skipPressed ? Theme.highlightColor : Theme.primaryColor) + "\">")
                    .arg("</font></u>")

            onAccepted: {
                root._internetConnectionSkipped = false
                acceptDestination = dateTimeSettingsEnabled ? dateTimeComponent : _accountSetupPage()
            }

            onSkipClicked: {
                root._internetConnectionSkipped = true
                acceptDestination = dateTimeSettingsEnabled ? dateTimeComponent : _accountSetupPage()
                pageStack.animatorPush(acceptDestination)
            }

            Component.onCompleted: _createStoreAccountPage()
        }
    }

    Component {
        id: dateTimeComponent

        DateTimeDialog {
            backNavigation: root._internetConnectionSkipped
            onStatusChanged: {
                if (status === PageStatus.Active) {
                    acceptDestination = root._accountSetupPage()
                }
            }
        }
    }

    Component {
        id: fingerEnrollmentComponent

        FingerEnrollmentWelcomeDialog {
            canSkip: true
            destination: tutorialMainComponent
            authenticationToken: root._fingerprintAuthenticationToken

            settings: fingerprintSettings
        }
    }

    Component {
        id: mandatorySecurityCodeComponent

        DeviceLockDialog {
            id: mandatorySecurityCodePage

            homeEncrypted: deviceLockSettings.homeEncrypted
            authorization: fingerprintSettings.hasSensor
                    ? fingerprintSettings.authorization
                    : deviceLockSettings.authorization

            onAuthenticated: {
                root._fingerprintAuthenticationToken = authenticationToken
                pageStack.animatorReplace(root._firstPageAfterUnlock)
            }
            onCanceled: pageStack.animatorPush(securityCodeRequiredWarningComponent)
        }
    }

    Component {
        id: securityCodeRequiredWarningComponent
        DeviceLockWarningDialog {
            id: warningDialog

            acceptDestination: root._firstPageAfterUnlock
        }
    }

    // Used if tutorial is not installed and will just quit the application
    // when started
    Component {
        id: noTutorialComponent

        Page {
            onStatusChanged: {
                if (status == PageStatus.Active) {
                    tutorialExitConf()
                    // Tutorial not installed so just quit
                    Qt.quit()
                }
            }
        }
    }
}
