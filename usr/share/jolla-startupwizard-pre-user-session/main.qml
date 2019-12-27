import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Lipstick 1.0
import com.jolla.settings.system 1.0
import com.jolla.startupwizard 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.configuration 1.0

// Don't use ApplicationWindow as it involves covers and other features that can't be handled
// before the user session begins.
Window {
    id: root

    ScreenBlank {
        // In pre-user-session stage, SUW has to mimic display on/off as lipstick isn't here to
        // manage it. No need to block touch events as mce will grab them.
        onDisplayOnRequested: dimmingRectangle.opacity = 0
        onDisplayOffRequested: dimmingRectangle.opacity = 1
    }

    // These are special properties required by silica components since we are using a Window
    // instead of an ApplicationWindow.
    property alias __silica_applicationwindow_instance: root
    property alias indicatorParentItem: indicatorParent
    property int _defaultPageOrientations: Orientation.Portrait

    property string _selectedLocale
    property string _selectedLanguage
    property Page _languagePage
    property Page _mdmPage

    property QtObject encryptionService

    function shutdown() {
        pageStack.enabled = false
        shutdownScreen.width = shutdownScreen.width // Break the bindings
        shutdownScreen.height = shutdownScreen.height
        shutdownScreen.rotation = shutdownScreen.rotation
        shutdownScreen.opacity = 1
    }

    function _continueFromWelcome() {
        if (languageModel.currentIndex == -1) {
            pageStack.animatorReplace(languagePageComponent)
        } else {
            _selectedLocale = languageModel.locale(languageModel.currentIndex)
            _selectedLanguage = languageModel.languageName(languageModel.currentIndex)

            pageStack.animatorReplace(termsOfUseComponent)
        }
    }

    function _selectedNewLocale(locale, language) {
        wizardManager.reloadTranslations(locale)
        _selectedLanguage = language
        _selectedLocale = locale
    }

    function _setVkbLayout(locale) {
        // set virtual keyboard layout correspondingly. Assuming such file exists if language is available
        var layout
        var lang = locale.substr(0, 2)
        if (locale.substr(0, 5) === "zh_HK") {
            layout = "zh_hwr_traditional.qml"
        } else if (lang === "zh") {
            layout = "zh_cn_pinyin.qml"
        } else if (lang === "nb") {
            layout = "no.qml"
        } else {
            layout = lang + ".qml"
        }
        currentLayoutConfig.value = layout

        // set enabled layouts. Initial layouts are locale and English (and HWR layouts for Chinese).
        if (lang === "zh") {
            enabledLayoutsConfig.value = ["zh_cn_pinyin.qml", "zh_hwr_traditional.qml", "zh_hwr_simplified.qml", "en.qml"]
        } else if (layout !== "en.qml") {
            enabledLayoutsConfig.value = [layout, "en.qml"]
        } else {
            enabledLayoutsConfig.value = [layout]
        }
    }

    function _setContactsShowSurnameFirst(showSurnameFirst) {
        contactOrderConfig.value = showSurnameFirst ? 1 : 0
    }

    function _finalize() {
        wizardManager.writePreUserSessionMarker()
        _setVkbLayout(_selectedLocale)
        var lang = _selectedLocale.substr(0, 2)
        _setContactsShowSurnameFirst(lang === "zh")
        languageModel.setSystemLocale(_selectedLocale, LanguageModel.UpdateWithoutReboot)
        if (encryptionService && encryptionService.available) {
            encryptionService.finalize()
        } else {
            wizardManager.triggerRestart()
        }
    }

    function _createMdmDialog() {
        if (_mdmPage) {
            return
        }
        var comp = Qt.createComponent(Qt.resolvedUrl("MdmTermsOfUseDialog.qml"))
        if (comp.status == Component.Error) {
            console.log("Not loading MDM terms:", comp.errorString())
            return
        }
        var props = {
            "acceptDestination": termsManager.hasVendorTermsOfUse ? vendorTermsComponent : pleaseWaitComponent,
            "localeName": Qt.binding(function() { return root._selectedLocale }),
            "startupWizardManager": wizardManager
        }
        var obj = comp.createObject(root, props)
        if (!obj) {
            console.log("Cannot create MDM object!")
            return
        }
        _mdmPage = obj
    }

    function _createEncryptionService() {
        if (encryptionService) {
            return
        }


        var encryptionServiceUrl = pageStack.resolveImportPage("Sailfish.Encryption.EncryptionService")
        if (!encryptionServiceUrl) {
            return
        }

        var comp = Qt.createComponent(encryptionServiceUrl)
        if (comp.status === Component.Error) {
            return
        }

        var obj = comp.createObject(root)
        if (!obj) {
            return
        }
        encryptionService = obj
    }

    Component.onCompleted: {
        _createMdmDialog()
        _createEncryptionService()
        pageStack.animatorPush(welcomeComponent)
    }

    width: Screen.width
    height: Screen.height

    StartupWizardManager {
        id: wizardManager
    }

    TermsOfUseManager {
        id: termsManager
        vendorPath: wizardManager.vendorTermsPath
    }

    LanguageModel {
        id: languageModel
    }

    ConfigurationValue {
        id: currentLayoutConfig
        key: "/sailfish/text_input/active_layout"
    }

    ConfigurationValue {
        id: enabledLayoutsConfig
        key: "/sailfish/text_input/enabled_layouts"
    }

    ConfigurationValue {
        id: contactOrderConfig
        key: "/org/nemomobile/contacts/display_label_order"
    }

    PageStack {
        id: pageStack

        property int currentOrientation: currentPage ? currentPage.orientation : root.orientation
        property bool verticalOrientation: currentOrientation === Orientation.Portrait ||
                                           currentOrientation === Orientation.PortraitInverted ||
                                           currentOrientation === Orientation.None
        property bool horizontalOrientation: currentOrientation === Orientation.Landscape ||
                                             currentOrientation === Orientation.LandscapeInverted

        // prevent some pagestack warnings
        property QtObject _pageStackIndicator: QtObject {
            property bool backIndicatorDown: false
            property bool forwardIndicatorDown: false
        }

        x: displayX
        y: displayY
        rotation: displayRotation

        // background fill
        Rectangle {
            anchors.fill: parent
            color: "black"
        }
    }

    // place indicator parent above all other items so that the indicator will not appear
    // under dialog background and be dimmed
    Item {
        id: indicatorParent
        anchors.fill: parent
    }

    Rectangle {
        id: dimmingRectangle
        anchors.fill: parent
        color: "black"
        opacity: 0.0
        Behavior on opacity { FadeAnimation { duration: 400 } }
    }

    ShutDownItem {
        id: shutdownScreen

        width: pageStack.currentPage ? pageStack.currentPage.width : root.width
        height: pageStack.currentPage ? pageStack.currentPage.height : root.height
        rotation: pageStack.currentPage ? pageStack.currentPage.rotation : 0

        opacity: 0
        message: {
            //: Shut down message
            //% "Goodbye!"
            qsTrId("startupwizard-la-goodbye") // trigger Qt Linguist translation
            return wizardManager.translatedText("startupwizard-la-goodbye", root._selectedLocale)
        }

        onOpacityAnimationFinished: if (opacity == 1) wizardManager.triggerShutdown()
    }

    Component {
        id: welcomeComponent
        WelcomePage {
            onStatusChanged: {
                if (status == PageStatus.Active) {
                    welcomeTimeout.start()
                }
            }
            onClicked: {
                welcomeTimeout.stop()
                root._continueFromWelcome()
            }
            Timer {
                id: welcomeTimeout
                interval: 10 * 1000
                onTriggered: root._continueFromWelcome()
            }
        }
    }

    Component {
        id: languagePageComponent
        LanguagePickerDialog {
            id: languagePickerDialog
            model: languageModel
            startupWizardManager: wizardManager
            canAccept: false

            onLocaleClicked: {
                root._selectedNewLocale(locale, language)
                languagePickerDialog.canAccept = true
                languagePickerDialog.acceptDestination = termsOfUseComponent
            }
        }
    }

    Component {
        id: termsOfUseComponent
        PlatformTermsOfUseDialog {
            acceptDestination: _mdmPage
                    ? _mdmPage
                    : (termsManager.hasVendorTermsOfUse ? vendorTermsComponent : pleaseWaitComponent)
            acceptDestinationAction: PageStackAction.Replace
            acceptDestinationReplaceTarget: null

            localeName: root._selectedLocale
            startupWizardManager: wizardManager
            termsOfUseManager: termsManager

            onShutdown: root.shutdown()
        }
    }

    Component {
        id: vendorTermsComponent
        VendorTermsOfUseDialog {
            acceptDestination: pleaseWaitComponent
            acceptDestinationAction: PageStackAction.Replace
            acceptDestinationReplaceTarget: null

            localeName: root._selectedLocale
            startupWizardManager: wizardManager
            termsOfUseManager: termsManager

            onShutdown: root.shutdown()
        }
    }

    Component {
        id: pleaseWaitComponent
        PleaseWaitPage {
            localeName: root._selectedLocale
            startupWizardManager: wizardManager

            encryptionStatus: encryptionService ? encryptionService.encryptionStatus : 0
            waiting: status < PageStatus.Active || restartTimer.running || encryptionService && encryptionService.busy
            onWaitingStopped: root._finalize()

            onStatusChanged: {
                if (status === PageStatus.Active) {
                    restartTimer.start()
                    if (encryptionService && encryptionService.available) {
                        encryptionService.encrypt()
                    }
                }
            }

            // Ensure the "please wait" text is displayed briefly before the screen goes black
            Timer {
                id: restartTimer
                interval: 5 * 1000
            }
        }
    }
}
