/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import com.jolla.startupwizard 1.0
import com.jolla.settings.system 1.0
import com.jolla.settings.accounts 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.devicelock 1.0

import MeeGo.QOfono 0.2
import Sailfish.Policy 1.0

ApplicationWindow {
    id: root

    readonly property string _accountName: "Jolla"
    property Page _accountPage
    property bool _internetConnectionSkipped
    property int _modemIndex
    property bool _pinRequested
    property variant _fingerprintAuthenticationToken

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
            tutorial = noTutorialComponent
        }
        return tutorial
    }

    function _setInitialPage(showSimPinQuery) {
        ofonoInitTimeout.stop()
        var pageComponent = showSimPinQuery ? pinQueryComponent : _firstPageAfterPinQuery
        var page = pageStack.replace(pageComponent, {}, PageStackAction.Immediate)
        if (pageComponent == tutorialMainComponent) {
            if (page.status === PageStatus.Active) {
                // don't allow back navigation from the tutorial
                page.backNavigation = false
                tutorialExitConf()
            }
        }
    }

    function _accountSetupPage() {
        if (root._internetConnectionSkipped) {
            return root._pageAfterAccountSetup
        } else if (accountFactory.jollaAccountExists()) { // Store exists for account (TODO JB#47405 : should be fixed for jolla-settings-account)
            console.log("User already has a", _accountName, "account, skipping", _accountName, "account creation. (Ignore the upcoming 'Great, your", _accountName, "account was added' message.)")
            return storeAccountAlreadyExistsComponent
        } else {
            return _createStoreAccountPage()
        }
    }

    function _createStoreAccountPage() {
        if (root._accountPage) {
            root._accountPage.destroy()
        }
        var props = { "wizardMode": true, "runningFromSettingsApp": false }
        root._accountPage = accountCreator.accountCreationPageForProvider(_accountName.toLowerCase(), props)
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

    Component {
        id: busyWaitComponent
        Page {
            Rectangle {
                anchors.fill: parent
                color: "black"
            }
            BusyIndicator {
                anchors.centerIn: parent
                size: BusyIndicatorSize.Large
            }
        }
    }

    StartupWizardManager {
        id: wizardManager
    }

    AccountFactory {
        id: accountFactory
    }

    ScreenBlank {
    }

    ConfigurationValue {
        id: reachedTutorialConf
        key: "/apps/jolla-startupwizard/reached_tutorial"
    }

    AccountCreationManager {
        id: accountCreator
        endDestination: root._pageAfterAccountSetup
        endDestinationAction: PageStackAction.Replace
        endDestinationReplaceTarget: null
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
            acceptDestination: dateTimeComponent

            //% "Setting up your internet connection at this point is highly recommended"
            headingText: qsTrId("startupwizard-he-internet_connection_heading")

            //% "With an internet connection you can set up your Store account and download essential apps now. You'll also be able to access the Store and OS updates immediately after setting up your account."
            bodyText: _accountPage ? qsTrId("startupwizard-la-internet_connection_body") : ""

            skipText: (_accountPage ?
                           //: Skip text if user doesn't want to set up the internet connection at the moment. (Text surrounded by %1 and %2 is underlined and colored differently)
                           //% "%1Skip%2 internet connection setup and set up my Store account later"
                           qsTrId("startupwizard-la-skip_internet_connection_account_specific") :
                           //: Skip text if user doesn't want to set up the internet connection at the moment. (Text surrounded by %1 and %2 is underlined and colored differently)
                           //% "%1Skip%2 internet connection setup"
                           qsTrId("startupwizard-la-skip_internet_connection"))
                    .arg("<u><font color=\"" + (skipPressed ? Theme.highlightColor : Theme.primaryColor) + "\">")
                    .arg("</font></u>")

            onAccepted: {
                root._internetConnectionSkipped = false
                acceptDestination = AccessPolicy.dateTimeSettingsEnabled ? dateTimeComponent : _accountSetupPage()
            }

            onSkipClicked: {
                root._internetConnectionSkipped = true
                acceptDestination = AccessPolicy.dateTimeSettingsEnabled ? dateTimeComponent : _accountSetupPage()
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

            onAccepted: {
                if (acceptDestination == tutorialMainComponent) {
                    // Entering tutorial so disable backNavigation
                    acceptDestinationInstance.backNavigation = false
                    tutorialExitConf()
                }
            }
        }
    }

    // This is only used if a store account already exists when the SUW is run; otherwise, the
    // Settings account creation flow takes care of triggering this flow.
    Component {
        id: storeAccountAlreadyExistsComponent

        WizardPostAccountCreationDialog {
            endDestination: root._pageAfterAccountSetup
            endDestinationAction: PageStackAction.Replace
            endDestinationReplaceTarget: null
            backNavigation: false
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
                if (status = PageStatus.Active) {
                    tutorialExitConf()
                    // Tutorial not installed so just quit
                    Qt.quit()
                }
            }
        }
    }

    // ---- the strings below aren't used yet; they have been added to get the translations done in
    // ----- in preparation for implementing JB#27908

    //: Heading when user is asked to provide the current location
    //% "Welcome! Where do you live?"
    property string _countryPickerHeading: qsTrId("startupwizard-he-welcome_where_do_you_live")

    //: Explains why user's location is being requested. It is used to define the WLAN frequences that can be used by the device.
    //% "This information is needed to define the allowed WLAN frequencies."
    property string _countryPickerIntro: qsTrId("startupwizard-la-country_requested_for_wlan")

    //: Allows user to choose current location from a list of countries, regions etc. if the automatically-chosen location was incorrect.
    //% "If we didn't guess correctly, please select your area below."
    property string _countryPickerFallbackExplanation: qsTrId("startupwizard-la-didnt_guess_area_correctly")
}
